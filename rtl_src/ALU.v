module ALU(
        input [3:0] ALUctrl,
        input [31:0] opnum1,
        input [31:0] opnum2,
        output [31:0] result,
        output zero_flag,
        output sign_flag,
        output carry_flag,
        output overflow_flag
    );

    reg [31:0] result_out;
    reg sign_out;
    reg carry_out;
    reg overflow_out;

    assign zero_flag = (result == 0);
    always @(*) begin
        case(ALUctrl)
            0: begin
                result_out = opnum1 & opnum2;
                sign_out = 0;
                carry_out = 0;
                overflow_out = 0;
            end
            1: begin
                result_out = opnum1 | opnum2;
                sign_out = 0;
                carry_out = 0;
                overflow_out = 0;
            end
            2: begin
                {carry_out, result_out} = opnum1 + opnum2;
                sign_out = 0;
                overflow_out = 0;
            end
            3: begin
                result_out = opnum1 << opnum2[4:0];
                sign_out = 0;
                carry_out = 0;
                overflow_out = 0;
            end
            4: begin
                result_out = opnum1 >> opnum2[4:0];
                sign_out = 0;
                carry_out = 0;
                overflow_out = 0;
            end
            5: begin
                result_out = opnum1 ^ opnum2;
                sign_out = 0;
                carry_out = 0;
                overflow_out = 0;
            end
            6: begin
                {carry_out, result_out} = opnum1 + ~(opnum2) + 1;
                sign_out = result_out[31];
                overflow_out = ((opnum1[31] != opnum2[31]) && (result_out[31] != opnum1[31]));
            end
            7: begin
                result_out =  ({32{opnum1[31]}} & (~(32'hffffffff >> opnum2[4:0]))) | (opnum1 >> opnum2[4:0]);
                sign_out = 0;
                carry_out = 0;
                overflow_out = 0;
            end
            default: begin
                result_out = 0;
                sign_out = 0;
                carry_out = 0;
                overflow_out = 0;
            end
        endcase
    end

    assign result = result_out;
    assign sign_flag = sign_out;
    assign carry_flag = carry_out;
    assign overflow_flag = overflow_out;

endmodule







