`ifndef TEST_FIX_ISSUE_UOP_VH
`define TEST_FIX_ISSUE_UOP_VH

`define ISSUE_UOP_RS1_LSB         0
`define ISSUE_UOP_RS1_MSB         4
`define ISSUE_UOP_RS2_LSB         5
`define ISSUE_UOP_RS2_MSB         9
`define ISSUE_UOP_RD_LSB          10
`define ISSUE_UOP_RD_MSB          14
`define ISSUE_UOP_IMM_LSB         15
`define ISSUE_UOP_IMM_MSB         46
`define ISSUE_UOP_ALUCTRL_LSB     47
`define ISSUE_UOP_ALUCTRL_MSB     50
`define ISSUE_UOP_CTRLBUS_LSB     51
`define ISSUE_UOP_CTRLBUS_MSB     87
`define ISSUE_UOP_USE_RS1_BIT     88
`define ISSUE_UOP_USE_RS2_BIT     89
`define ISSUE_UOP_WRITES_RD_BIT   90
`define ISSUE_UOP_IS_LS_BIT       91
`define ISSUE_UOP_IS_CTRL_BIT     92
`define ISSUE_UOP_IS_PAIRX_BIT    93
`define ISSUE_UOP_PRED_TAKEN_BIT  94
`define ISSUE_UOP_W               95

`endif
