module Hazard_detection(
    //
    input wire[32-1:0] instr,
    input wire         memread_EX,
    //input wire         regwrite_EX,
    input wire[5-1:0]  rs1_in_ID,
    input wire[5-1:0]  rs2_in_ID,
    input wire[5-1:0]  rd_from_ID,
    // 
    output wire load_use_hazard_detected
);

    //用于确定是否use了rs1或rs2
    wire RD1_used;
    wire RD2_used; 

    wire[6:0] opcode;
    assign    opcode = instr[6:0]  ;

    wire R_type = opcode == 7'b0110011; //R-type
    wire I_type = (opcode == 7'b0010011) | (opcode == 7'b0000011); //I-type imm load type
    wire S_type = opcode == 7'b0100011; //s-type store
    wire U_type = opcode == 7'b0110111; //U-type lui
    wire B_type = opcode == 7'b1100011; //B-type branch
    wire J_type = opcode == 7'b1101111; //J-type Jal

    assign RD1_used = R_type | I_type | S_type | B_type ;
    assign RD2_used = R_type | S_type | B_type;
    
    //------------------------------------------------- load use hazard
    wire op1_occur_load_use_hazard = memread_EX & (rs1_in_ID == rd_from_ID) & (rs1_in_ID != 5'h0) & RD1_used ;
    wire op2_occur_load_use_hazard = memread_EX & (rs2_in_ID == rd_from_ID) & (rs2_in_ID != 5'h0) & RD2_used ;
    assign  load_use_hazard_detected  = op1_occur_load_use_hazard | op2_occur_load_use_hazard;

    ////------------------------------------------------- branch hazard (only branch type instr need not all two-op instr)
    //wire op1_occur_branch_hazard   = regwrite_EX & (rs1_in_ID == rd_from_EX) & (rs1_in_ID != 5'h0) & instr_is_b_type ;
    //wire op2_occur_branch_hazard   = regwrite_EX & (rs2_in_ID == rd_from_EX) & (rs2_in_ID != 5'h0) & instr_is_b_type ;
    //wire branch_hazard_detected    = op1_occur_branch_hazard | op2_occur_branch_hazard;
    //
    //assign control_bus_sel = load_use_hazard_detected | branch_hazard_detected; //both load or branch-use need insert a bubble
    //assign IF_ID_instr_reg_hold  = load_use_hazard_detected | branch_hazard_detected;
    //assign pc_reg_hold     = load_use_hazard_detected | branch_hazard_detected;

endmodule

