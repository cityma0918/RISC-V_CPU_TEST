module registerFile #(parameter ADDR_WIDTH = 5, parameter DATA_WIDTH = 32)(
        input clk,
        input rst_n,
        input [ADDR_WIDTH-1:0] raddr0_1,
        input [ADDR_WIDTH-1:0] raddr0_2,
        output [DATA_WIDTH-1:0] rdata0_1,
        output [DATA_WIDTH-1:0] rdata0_2,
        input [ADDR_WIDTH-1:0] raddr1_1,
        input [ADDR_WIDTH-1:0] raddr1_2,
        output [DATA_WIDTH-1:0] rdata1_1,
        output [DATA_WIDTH-1:0] rdata1_2,
        input [DATA_WIDTH-1:0] wdata0,
        input [ADDR_WIDTH-1:0] waddr0,
        input w_en0,
        input [DATA_WIDTH-1:0] wdata1,
        input [ADDR_WIDTH-1:0] waddr1,
        input w_en1
    );

    integer i;
    reg [DATA_WIDTH-1:0] rf [0:(2**ADDR_WIDTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
                rf[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            if (w_en0 && (waddr0 != {ADDR_WIDTH{1'b0}})) begin
                rf[waddr0] <= wdata0;
            end
            if (w_en1 && (waddr1 != {ADDR_WIDTH{1'b0}})) begin
                rf[waddr1] <= wdata1;
            end
        end
    end

    assign rdata0_1 = (raddr0_1 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : rf[raddr0_1];
    assign rdata0_2 = (raddr0_2 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : rf[raddr0_2];
    assign rdata1_1 = (raddr1_1 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : rf[raddr1_1];
    assign rdata1_2 = (raddr1_2 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : rf[raddr1_2];
endmodule
