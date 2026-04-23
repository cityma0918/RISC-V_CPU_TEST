
// this module support simple data hazard forwarding
module Forwarding_unit(
    // source index input
    input[5-1:0] rs1_from_ID,
    input[5-1:0] rs2_from_ID,      
    input[5-1:0] rs1_in_ID,
    input[5-1:0] rs2_in_ID,
    // destination index input
    input[5-1:0] rd_from_EX,
    input[5-1:0] rd_from_MEM,
    // regwrite flag input
    input        regwrite_in_MEM,
    input        regwrite_in_WB,
    // forward sel for EX
    output[1:0] forwardA_sel_EX,
    output[1:0] forwardB_sel_EX,
    // forward sel for ID
    //output[1:0] forwardA_sel_ID,
    //output[1:0] forwardB_sel_ID
    output forwardA_sel_ID,
    output forwardB_sel_ID
    );

    wire forwardA_mem_stage_en = (rs1_from_ID == rd_from_EX ) & (rs1_from_ID != 5'b0) & regwrite_in_MEM;
    wire forwardA_wb_stage_en  = (rs1_from_ID == rd_from_MEM) & (rs1_from_ID != 5'b0) & regwrite_in_WB ;
    assign forwardA_sel_EX = forwardA_mem_stage_en ? 2'b10 //higher priority 确保用到最新的数据
                        : forwardA_wb_stage_en  ? 2'b01
                        : 2'b00;
    
    wire forwardB_mem_stage_en = (rs2_from_ID == rd_from_EX ) & (rs2_from_ID != 5'b0) & regwrite_in_MEM;
    wire forwardB_wb_stage_en  = (rs2_from_ID == rd_from_MEM) & (rs2_from_ID != 5'b0) & regwrite_in_WB ;
    assign forwardB_sel_EX = forwardB_mem_stage_en ? 2'b10
                        : forwardB_wb_stage_en  ? 2'b01
                        : 2'b00;

// if the DataRAM  Read can be done in single cycle,
// the forward can be another choose ,that 2'b01 -> dataRAM-RD result
// howerver this type will lead a long time path -> "address -> DataRAM -> Alu" -> which will make our cpu frenquency down !!!

//----------------------------- decode need forwarding
//wire forwardA_Decode_mem_stage_en = (rs1_in_ID == rd_from_EX ) & (rs1_in_ID != 5'b0) & regwrite_in_MEM;
//wire forwardA_Decode_wb_stage_en  = (rs1_in_ID == rd_from_MEM) & (rs1_in_ID != 5'b0) & regwrite_in_WB ;
//assign forwardA_sel_ID        = forwardA_Decode_mem_stage_en ? 2'b11 //higher priority
//                                  : forwardA_Decode_wb_stage_en  ? 2'b10
//                                  : 2'b00;
//
//wire forwardB_Decode_mem_stage_en = (rs2_in_ID == rd_from_EX ) & (rs2_in_ID != 5'b0) & regwrite_in_MEM;
//wire forwardB_Decode_wb_stage_en  = (rs2_in_ID == rd_from_MEM) & (rs2_in_ID != 5'b0) & regwrite_in_WB ;
//assign forwardB_sel_ID        = forwardB_Decode_mem_stage_en ? 2'b11 //higher priority
//                                  : forwardB_Decode_wb_stage_en  ? 2'b10
//                                  : 2'b00;

    wire forwardA_Decode_wb_stage_en  = (rs1_in_ID == rd_from_MEM) & (rs1_in_ID != 5'b0) & regwrite_in_WB ;
    assign forwardA_sel_ID        =    forwardA_Decode_wb_stage_en  ? 1'b1
                                      : 1'b0;

    wire forwardB_Decode_wb_stage_en  = (rs2_in_ID == rd_from_MEM) & (rs2_in_ID != 5'b0) & regwrite_in_WB ;
    assign forwardB_sel_ID        =    forwardB_Decode_wb_stage_en  ? 1'b1
                                      : 1'b0;

endmodule
