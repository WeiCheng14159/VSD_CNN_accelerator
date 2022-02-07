`ifndef __INFMASTER__
`define __INFMASTER__
`include "../../include/AXI_define.svh"

interface inf_Master;
  // AW
  logic [`AXI_ID_BITS   -1:0] awid;
  logic [`AXI_ADDR_BITS -1:0] awaddr;
  logic [`AXI_LEN_BITS  -1:0] awlen;
  logic [`AXI_SIZE_BITS -1:0] awsize;
  logic [`AXI_BURST_BITS-1:0] awburst;
  logic                       awvalid;
  logic                       awready;
  // W
  logic [ `AXI_DATA_BITS-1:0] wdata;
  logic [ `AXI_STRB_BITS-1:0] wstrb;
  logic                       wlast;
  logic                       wvalid;
  logic                       wready;
  // B
  logic [`AXI_ID_BITS   -1:0] bid;
  logic [`AXI_BURST_BITS-1:0] bresp;
  logic                       bvalid;
  logic                       bready;
  // AR
  logic [`AXI_ID_BITS   -1:0] arid;
  logic [`AXI_ADDR_BITS -1:0] araddr;
  logic [`AXI_LEN_BITS  -1:0] arlen;
  logic [`AXI_SIZE_BITS -1:0] arsize;
  logic [`AXI_BURST_BITS-1:0] arburst;
  logic                       arvalid;
  logic                       arready;
  // R
  logic [ `AXI_ID_BITS  -1:0] rid;
  logic [ `AXI_DATA_BITS-1:0] rdata;
  logic [ `AXI_RESP_BITS-1:0] rresp;
  logic                       rlast;
  logic                       rvalid;
  logic                       rready;

  modport M2AXIin(
      input awready,
      input wready,
      input bid,
      input bresp,
      input bvalid,
      input arready,
      input rid,
      input rdata,
      input rresp,
      input rlast,
      input rvalid
  );
  modport M2AXIout(
      output awid,
      output awaddr,
      output awlen,
      output awsize,
      output awburst,
      output awvalid,
      output wdata,
      output wstrb,
      output wlast,
      output wvalid,
      output bready,
      output arid,
      output araddr,
      output arlen,
      output arsize,
      output arburst,
      output arvalid,
      output rready
  );

  modport AXI2Min(
      input awid,
      input awaddr,
      input awlen,
      input awsize,
      input awburst,
      input awvalid,
      input wdata,
      input wstrb,
      input wlast,
      input wvalid,
      input bready,
      input arid,
      input araddr,
      input arlen,
      input arsize,
      input arburst,
      input arvalid,
      input rready
  );
  modport AXI2Mout(
      output awready,
      output wready,
      output bid,
      output bresp,
      output bvalid,
      output arready,
      output rid,
      output rdata,
      output rresp,
      output rlast,
      output rvalid
  );

endinterface : inf_Master
`endif
