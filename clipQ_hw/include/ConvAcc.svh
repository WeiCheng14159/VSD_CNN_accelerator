// `ifndef CONV_ACC_SVH
// `define CONV_ACC_SVH

`define DATA_BUS_WIDTH 32
`define QDATA_BUS_WIDTH 8
`define ADDR_BUS_WIDTH 32
`define EMPTY_ADDR ({`ADDR_BUS_WIDTH{1'b0}})
`define EMPTY_DATA ({`DATA_BUS_WIDTH{1'b0}})
`define EMPTY_QDATA ({`QDATA_BUS_WIDTH{1'b0}})

`define WRITE_ENB (1'b0)
`define WRITE_DIS (1'b1)

`define READ_ENB (1'b1)
`define READ_DIS (1'b0)

`define IDLE_MODE 0
`define CONV_1x1_MODE 1
`define MAX_POOL_MODE 2
`define CONV_3x3_MODE 3

// `endif
