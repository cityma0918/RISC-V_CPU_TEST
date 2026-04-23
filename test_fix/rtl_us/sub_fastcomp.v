module sub_fastcomp(
        input [31:0] opnum1,
        input [31:0] opnum2,
        output zero_flag,
        output sign_flag,
        output carry_flag,
        output overflow_flag
    );

    wire [31:0] result_out;
    wire sign_out;
    wire carry_out;
    wire overflow_out;

    assign  {carry_out, result_out} = opnum1 + ~(opnum2) + 1;
    assign  sign_out = result_out[31];
    assign  overflow_out = ((opnum1[31] != opnum2[31]) && (result_out[31] != opnum1[31]));
    assign  zero_flag = (result_out == 0);

    assign sign_flag = sign_out;
    assign carry_flag = carry_out;
    assign overflow_flag = overflow_out;

endmodule







