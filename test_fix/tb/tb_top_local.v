`timescale 1ns/1ps

module tb_top_local;
    localparam [31:0] SIGNATURE_ADDR = 32'h0000_1000;

    reg clk;
    reg rst_n;

    wire        commit0_valid;
    wire [31:0] commit0_pc;
    wire [31:0] commit0_insn;
    wire [4:0]  commit0_rd;
    wire [31:0] commit0_rd_wdata;
    wire [31:0] commit0_mem_addr;
    wire [3:0]  commit0_mem_rmask;
    wire [3:0]  commit0_mem_wmask;
    wire [31:0] commit0_mem_rdata;
    wire [31:0] commit0_mem_wdata;

    wire        commit1_valid;
    wire [31:0] commit1_pc;
    wire [31:0] commit1_insn;
    wire [4:0]  commit1_rd;
    wire [31:0] commit1_rd_wdata;
    wire [31:0] commit1_mem_addr;
    wire [3:0]  commit1_mem_rmask;
    wire [3:0]  commit1_mem_wmask;
    wire [31:0] commit1_mem_rdata;
    wire [31:0] commit1_mem_wdata;

    integer cycle;
    integer max_cycles;
    integer trace_fd;
    integer lane1_commits;
    integer signature_value;
    string trace_file;
    string vcd_file;

    cpu_core u_cpu_core(
        .clk(clk),
        .rst_n(rst_n),
        .commit0_valid(commit0_valid),
        .commit0_pc(commit0_pc),
        .commit0_insn(commit0_insn),
        .commit0_rd(commit0_rd),
        .commit0_rd_wdata(commit0_rd_wdata),
        .commit0_mem_addr(commit0_mem_addr),
        .commit0_mem_rmask(commit0_mem_rmask),
        .commit0_mem_wmask(commit0_mem_wmask),
        .commit0_mem_rdata(commit0_mem_rdata),
        .commit0_mem_wdata(commit0_mem_wdata),
        .commit1_valid(commit1_valid),
        .commit1_pc(commit1_pc),
        .commit1_insn(commit1_insn),
        .commit1_rd(commit1_rd),
        .commit1_rd_wdata(commit1_rd_wdata),
        .commit1_mem_addr(commit1_mem_addr),
        .commit1_mem_rmask(commit1_mem_rmask),
        .commit1_mem_wmask(commit1_mem_wmask),
        .commit1_mem_rdata(commit1_mem_rdata),
        .commit1_mem_wdata(commit1_mem_wdata)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        cycle = 0;
        max_cycles = 20000;
        trace_fd = 0;
        lane1_commits = 0;
        signature_value = 0;

        if (!$value$plusargs("timeout=%d", max_cycles)) begin
        end

        if ($value$plusargs("trace=%s", trace_file)) begin
            trace_fd = $fopen(trace_file, "w");
        end
        else begin
            trace_fd = $fopen("rtl_trace.log", "w");
        end

        if (trace_fd == 0) begin
            $display("[tb] failed to open trace file");
            $finish;
        end

        $fdisplay(trace_fd, "# RVFI-lite trace columns");
        $fdisplay(trace_fd, "# pc insn rd rd_wdata mem_addr mem_rmask mem_wmask mem_rdata mem_wdata trap trap_cause");
        $fdisplay(trace_fd, "# hex hex hex2 hex hex hex1 hex1 hex hex dec hex");

        if ($value$plusargs("vcd=%s", vcd_file)) begin
            $dumpfile(vcd_file);
            $dumpvars(0, tb_top_local);
        end

        rst_n = 1'b0;
        repeat (8) @(posedge clk);
        rst_n = 1'b1;
    end

    task automatic write_trace;
        input [31:0] pc;
        input [31:0] insn;
        input [4:0]  rd;
        input [31:0] rd_wdata;
        input [31:0] mem_addr;
        input [3:0]  mem_rmask;
        input [3:0]  mem_wmask;
        input [31:0] mem_rdata;
        input [31:0] mem_wdata;
        begin
            $fwrite(trace_fd,
                "%08x %08x %02x %08x %08x %1x %1x %08x %08x %1d %08x\n",
                pc,
                insn,
                rd,
                rd_wdata,
                mem_addr,
                mem_rmask,
                mem_wmask,
                mem_rdata,
                mem_wdata,
                1'b0,
                32'h0
            );
        end
    endtask

    always @(posedge clk) begin
        if (!rst_n) begin
            cycle <= 0;
        end
        else begin
            cycle <= cycle + 1;

            if (commit0_valid) begin
                write_trace(
                    commit0_pc,
                    commit0_insn,
                    commit0_rd,
                    commit0_rd_wdata,
                    commit0_mem_addr,
                    commit0_mem_rmask,
                    commit0_mem_wmask,
                    commit0_mem_rdata,
                    commit0_mem_wdata
                );
            end

            if (commit1_valid) begin
                write_trace(
                    commit1_pc,
                    commit1_insn,
                    commit1_rd,
                    commit1_rd_wdata,
                    commit1_mem_addr,
                    commit1_mem_rmask,
                    commit1_mem_wmask,
                    commit1_mem_rdata,
                    commit1_mem_wdata
                );
                lane1_commits <= lane1_commits + 1;
            end

            if (commit0_valid && (commit0_mem_wmask == 4'hf) && (commit0_mem_addr == SIGNATURE_ADDR)) begin
                signature_value = commit0_mem_wdata;
                $display("[tb] signature value=%0d cycles=%0d lane1_commits=%0d", signature_value, cycle, lane1_commits + (commit1_valid ? 1 : 0));
                if (trace_fd != 0) begin
                    $fclose(trace_fd);
                end
                $finish;
            end

            if (cycle > max_cycles) begin
                $display("[tb] TIMEOUT after %0d cycles", cycle);
                if (trace_fd != 0) begin
                    $fclose(trace_fd);
                end
                $finish;
            end
        end
    end
endmodule
