module maincontroller(
        input [2:0]fun3,
        input [6:0]fun7,
        input [6:0]opcode,
        output [3:0]ALUctrl,
        output addi,
        output auipc,
        output jal,
        output jalr,
        output lui,
        output add,
        output sub,
        output sltiu,
        output sltu,
        output bne,
        output beq,
        output sll,
        output srl,
        output and_,
        output andi,
        output or_,
        output ori,
        output xor_,
        output xori,
        output srli,
        output slli,
        output bge,
        output bgeu,
        output sra,
        output srai,
        output blt,
        output bltu,
        output slt,
        output slti,
        output lbu,
        output lb,
        output sb,
        output sw,
        output lw,
        output sh,
        output lh,
        output lhu
    );

    //R型指令
    assign add = (opcode == 7'b0110011) && (fun3 == 3'b000) && (fun7 == 7'b0000000);    
    assign sub = (opcode == 7'b0110011) && (fun3 == 3'b000) && (fun7 == 7'b0100000);
    assign xor_ = (opcode == 7'b0110011) && (fun3 == 3'b100) && (fun7 == 7'b0000000);
    assign or_ = (opcode == 7'b0110011) && (fun3 == 3'b110) && (fun7 == 7'b0000000);
    assign and_ = (opcode == 7'b0110011) && (fun3 == 3'b111) && (fun7 == 7'b0000000);
    assign sll = (opcode == 7'b0110011) && (fun3 == 3'b001) && (fun7 == 7'b0000000);
    assign srl = (opcode == 7'b0110011) && (fun3 == 3'b101) && (fun7 == 7'b0000000);
    assign sra = (opcode == 7'b0110011) && (fun3 == 3'b101) && (fun7 == 7'b0100000);
    assign slt = (opcode == 7'b0110011) && (fun3 == 3'b010) && (fun7 == 7'b0000000);
    assign sltu = (opcode == 7'b0110011) && (fun3 == 3'b011) && (fun7 == 7'b0000000);

    //运算I型指令
    assign addi = (opcode == 7'b0010011) && (fun3 == 3'b000);
    assign xori = (opcode == 7'b0010011) && (fun3 == 3'b100);
    assign ori = (opcode == 7'b0010011) && (fun3 == 3'b110);
    assign andi = (opcode == 7'b0010011) && (fun3 == 3'b111);
    assign slli = (opcode == 7'b0010011) && (fun3 == 3'b001) && (fun7 == 7'b0000000);
    assign srli = (opcode == 7'b0010011) && (fun3 == 3'b101) && (fun7 == 7'b0000000);
    assign srai = (opcode == 7'b0010011) && (fun3 == 3'b101) && (fun7 == 7'b0100000);
    assign slti = (opcode == 7'b0010011) && (fun3 == 3'b010);
    assign sltiu = (opcode == 7'b0010011) && (fun3 == 3'b011);

    //load指令
    assign lb = (opcode == 7'b0000011) && (fun3 == 3'b000);
    assign lh = (opcode == 7'b0000011) && (fun3 == 3'b001);
    assign lw = (opcode == 7'b0000011) && (fun3 == 3'b010);
    assign lbu = (opcode == 7'b0000011) && (fun3 == 3'b100);
    assign lhu = (opcode == 7'b0000011) && (fun3 == 3'b101);
    
    //store指令
    assign sb = (opcode == 7'b0100011) && (fun3 == 3'b000);
    assign sh = (opcode == 7'b0100011) && (fun3 == 3'b001);
    assign sw = (opcode == 7'b0100011) && (fun3 == 3'b010);

    //控制类指令    
    assign beq = (opcode == 7'b1100011) && (fun3 == 3'b000);
    assign bne = (opcode == 7'b1100011) && (fun3 == 3'b001);
    assign blt = (opcode == 7'b1100011) && (fun3 == 3'b100);
    assign bge = (opcode == 7'b1100011) && (fun3 == 3'b101);
    assign bltu = (opcode == 7'b1100011) && (fun3 == 3'b110);
    assign bgeu = (opcode == 7'b1100011) && (fun3 == 3'b111);
    assign jal = (opcode == 7'b1101111);
    assign jalr = (opcode == 7'b1100111) && (fun3 == 3'b000);
    assign lui = (opcode == 7'b0110111);
    assign auipc = (opcode == 7'b0010111);
    

    assign ALUctrl = (sub | sltiu | sltu | bne | beq | bge | bgeu | blt | bltu | slt | slti) ? 4'd6 :
           (and_ | andi) ? 4'd0 :
           (or_ | ori) ? 4'd1 :
           (xor_ | xori) ? 4'd5 :
           (sll | slli) ? 4'd3 :
           (sra | srai )? 4'd7:
           (srli | srl) ? 4'd4: 
           4'd2;

endmodule
