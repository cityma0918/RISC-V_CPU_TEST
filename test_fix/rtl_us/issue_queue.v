`include "issue_uop.vh"

module issue_queue #(
        parameter integer DEPTH = 8
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire flush,

        input  wire push0_valid,
        input  wire [31:0] push0_pc,
        input  wire [31:0] push0_instr,
        input  wire [`ISSUE_UOP_W-1:0] push0_uop,
        input  wire push1_valid,
        input  wire [31:0] push1_pc,
        input  wire [31:0] push1_instr,
        input  wire [`ISSUE_UOP_W-1:0] push1_uop,

        input  wire pop0,
        input  wire pop1,

        output wire head0_valid,
        output wire [31:0] head0_pc,
        output wire [31:0] head0_instr,
        output wire [`ISSUE_UOP_W-1:0] head0_uop,
        output wire head1_valid,
        output wire [31:0] head1_pc,
        output wire [31:0] head1_instr,
        output wire [`ISSUE_UOP_W-1:0] head1_uop,
        output wire [31:0] free_slots
    );

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = i;
        end
    endfunction

    localparam integer PTR_W = (DEPTH <= 2) ? 1 : clog2(DEPTH);
    localparam integer CNT_W = clog2(DEPTH + 1);

    reg [31:0] q_pc [0:DEPTH-1];
    reg [31:0] q_instr [0:DEPTH-1];
    reg [`ISSUE_UOP_W-1:0] q_uop [0:DEPTH-1];
    reg [PTR_W-1:0] rd_ptr;
    reg [PTR_W-1:0] wr_ptr;
    reg [CNT_W-1:0] count_r;

    function [PTR_W-1:0] ptr_inc;
        input [PTR_W-1:0] ptr;
        begin
            if (ptr == (DEPTH - 1)) begin
                ptr_inc = {PTR_W{1'b0}};
            end
            else begin
                ptr_inc = ptr + {{(PTR_W-1){1'b0}}, 1'b1};
            end
        end
    endfunction

    wire [PTR_W-1:0] head1_idx = (rd_ptr == (DEPTH - 1)) ? {PTR_W{1'b0}} :
                                 (rd_ptr + {{(PTR_W-1){1'b0}}, 1'b1});

    assign head0_valid = (count_r != {CNT_W{1'b0}});
    assign head1_valid = (count_r > {{(CNT_W-1){1'b0}}, 1'b1});
    assign head0_pc = head0_valid ? q_pc[rd_ptr] : 32'h0;
    assign head0_instr = head0_valid ? q_instr[rd_ptr] : 32'h0;
    assign head0_uop = head0_valid ? q_uop[rd_ptr] : {`ISSUE_UOP_W{1'b0}};
    assign head1_pc = head1_valid ? q_pc[head1_idx] : 32'h0;
    assign head1_instr = head1_valid ? q_instr[head1_idx] : 32'h0;
    assign head1_uop = head1_valid ? q_uop[head1_idx] : {`ISSUE_UOP_W{1'b0}};
    assign free_slots = DEPTH - {{(32-CNT_W){1'b0}}, count_r};

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            q_pc[i] = 32'h0;
            q_instr[i] = 32'h0;
            q_uop[i] = {`ISSUE_UOP_W{1'b0}};
        end
    end

    always @(posedge clk or negedge rst_n) begin : queue_update
        integer pop_cnt;
        integer push_cnt;
        integer avail_slots;
        reg pop0_ok;
        reg pop1_ok;
        reg push0_ok;
        reg push1_ok;
        reg [PTR_W-1:0] rd_next;
        reg [PTR_W-1:0] wr_next;
        if (!rst_n || flush) begin
            rd_ptr <= {PTR_W{1'b0}};
            wr_ptr <= {PTR_W{1'b0}};
            count_r <= {CNT_W{1'b0}};
        end
        else begin
            pop0_ok = pop0 && (count_r != {CNT_W{1'b0}});
            pop1_ok = pop1 && pop0_ok && (count_r > {{(CNT_W-1){1'b0}}, 1'b1});
            pop_cnt = (pop0_ok ? 1 : 0) + (pop1_ok ? 1 : 0);

            avail_slots = DEPTH - count_r + pop_cnt;
            push0_ok = push0_valid && (avail_slots > 0);
            push1_ok = push1_valid && push0_ok && (avail_slots > 1);
            push_cnt = (push0_ok ? 1 : 0) + (push1_ok ? 1 : 0);

            rd_next = rd_ptr;
            if (pop0_ok) begin
                rd_next = ptr_inc(rd_next);
            end
            if (pop1_ok) begin
                rd_next = ptr_inc(rd_next);
            end

            wr_next = wr_ptr;
            if (push0_ok) begin
                q_pc[wr_next] <= push0_pc;
                q_instr[wr_next] <= push0_instr;
                q_uop[wr_next] <= push0_uop;
                wr_next = ptr_inc(wr_next);
            end
            if (push1_ok) begin
                q_pc[wr_next] <= push1_pc;
                q_instr[wr_next] <= push1_instr;
                q_uop[wr_next] <= push1_uop;
                wr_next = ptr_inc(wr_next);
            end

            rd_ptr <= rd_next;
            wr_ptr <= wr_next;
            count_r <= count_r + push_cnt - pop_cnt;
        end
    end
endmodule
