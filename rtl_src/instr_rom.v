module instr_rom #(
        parameter integer MEM_WORDS = 4096
    )(
        input  [31:0] raddr,
        input  r_en,
        output [31:0] rdata,
        output [63:0] rdata_pair
    );

    integer i;
    integer idx;
    string memhex;
    reg [31:0] cpu_instr_rom [0:MEM_WORDS-1];
    reg [31:0] rdata_out;
    reg [63:0] rdata_pair_out;

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            cpu_instr_rom[i] = 32'h0;
        end
        if ($value$plusargs("memhex=%s", memhex)) begin
            $readmemh(memhex, cpu_instr_rom);
        end
    end

    always @(*) begin
        if (r_en) begin
            idx = raddr[31:2];
            if ((idx >= 0) && (idx < MEM_WORDS)) begin
                rdata_out = cpu_instr_rom[idx];
                if ((idx + 1) < MEM_WORDS) begin
                    rdata_pair_out = {cpu_instr_rom[idx + 1], cpu_instr_rom[idx]};
                end
                else begin
                    rdata_pair_out = {32'h0, cpu_instr_rom[idx]};
                end
            end
            else begin
                rdata_out = 32'h0;
                rdata_pair_out = 64'h0;
            end
        end
        else begin
            rdata_out = 32'h0;
            rdata_pair_out = 64'h0;
        end
    end

    assign rdata = rdata_out;
    assign rdata_pair = rdata_pair_out;
endmodule
