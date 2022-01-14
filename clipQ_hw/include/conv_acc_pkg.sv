`ifndef CONV_ACC_PKG_SV
`define CONV_ACC_PKG_SV

package conv_acc_pkg;

typedef enum logic [3:0] {
  CONV_1x1_MODE = 4'h1,
  MAX_POOL_MODE = 4'h2,
  CONV_3x3_MODE = 4'h3,
  IDLE_MODE     = 4'h0
} conv_acc_mode_t;

endpackage

`endif