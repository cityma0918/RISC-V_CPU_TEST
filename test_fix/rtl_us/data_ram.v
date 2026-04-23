module data_ram #(
        parameter integer MEM_WORDS = 4096
    )(
        input clk,
        input w_en,
        input r_en,
        input [1:0] store_type,
        input [31:0] raddr,
        input [31:0] waddr,
        input [31:0] wdata,
        output [31:0] rdata
    );

    integer i;
    integer r_index;
    string memhex;
    reg [31:0] dram [0:MEM_WORDS-1];
    reg [31:0] rdata_out;

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            dram[i] = 32'h0;
        end
        if ($value$plusargs("memhex=%s", memhex)) begin
            $readmemh(memhex, dram);
        end
    end

    always @(*) begin
        if (r_en) begin
            r_index = raddr[31:2];
            if ((r_index >= 0) && (r_index < MEM_WORDS)) begin
                rdata_out = dram[r_index];
            end
            else begin
                rdata_out = 32'h0;
            end
        end
        else begin
            rdata_out = 32'h0;
        end
    end

    assign rdata = rdata_out;

    always @(posedge clk) begin
        if (w_en && (waddr[31:2] < MEM_WORDS)) begin
            case (store_type)
                2'b00: begin
                    case (waddr[1:0])
                        2'b00: dram[waddr[31:2]][7:0] <= wdata[7:0];
                        2'b01: dram[waddr[31:2]][15:8] <= wdata[7:0];
                        2'b10: dram[waddr[31:2]][23:16] <= wdata[7:0];
                        2'b11: dram[waddr[31:2]][31:24] <= wdata[7:0];
                    endcase
                end
                2'b01: begin
                    case (waddr[1])
                        1'b0: dram[waddr[31:2]][15:0] <= wdata[15:0];
                        1'b1: dram[waddr[31:2]][31:16] <= wdata[15:0];
                    endcase
                end
                default: begin
                    dram[waddr[31:2]] <= wdata;
                end
            endcase
        end
    end
endmodule
