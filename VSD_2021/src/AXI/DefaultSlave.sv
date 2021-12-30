`include "../../include/AXI_define.svh"

module DefaultSlave (
    input                              clk,
    rst,
    // AW
    input        [`AXI_IDS_BITS  -1:0] awid_i,
    input        [`AXI_ADDR_BITS -1:0] awaddr_i,
    input        [`AXI_LEN_BITS  -1:0] awlen_i,
    input        [`AXI_SIZE_BITS -1:0] awsize_i,
    input        [`AXI_BURST_BITS-1:0] awburst_i,
    input                              awvalid_i,
    output logic                       awready_o,
    // W
    input        [`AXI_DATA_BITS -1:0] wdata_i,
    input        [`AXI_STRB_BITS -1:0] wstrb_i,
    input                              wlast_i,
    input                              wvalid_i,
    output logic                       wready_o,
    // B
    output logic [`AXI_IDS_BITS  -1:0] bid_o,
    output logic [`AXI_RESP_BITS -1:0] bresp_o,
    output logic                       bvalid_o,
    input                              bready_i,
    // AR
    input        [`AXI_IDS_BITS  -1:0] arid_i,
    input        [`AXI_ADDR_BITS -1:0] araddr_i,
    input        [`AXI_LEN_BITS  -1:0] arlen_i,
    input        [`AXI_SIZE_BITS -1:0] arsize_i,
    input        [`AXI_BURST_BITS-1:0] arburst_i,
    input                              arvalid_i,
    output logic                       arready_o,
    // R
    output logic [`AXI_IDS_BITS  -1:0] rid_o,
    output logic [`AXI_DATA_BITS -1:0] rdata_o,
    output logic [`AXI_RESP_BITS -1:0] rresp_o,
    output logic                       rlast_o,
    output logic                       rvalid_o,
    input                              rready_i
);

  // Handshake
  logic awhns, arhns, whns, rhns, bhns;
  assign awhns = awvalid_i & awready_o;
  assign arhns = arvalid_i & arready_o;
  assign whns  = wvalid_i & wready_o;
  assign rhns  = rvalid_o & rready_i;
  assign bhns  = bvalid_o & bready_i;
  parameter IDLE = 3'b0, READ = 3'b1, WRITE = 3'b10;

  logic [2:0] STATE, NEXT;

  logic [`AXI_IDS_BITS  -1:0] arid;
  logic [`AXI_LEN_BITS  -1:0] arlen;
  logic [`AXI_SIZE_BITS -1:0] size;
  logic [`AXI_BURST_BITS-1:0] burst;
  logic [`AXI_LEN_BITS  -1:0] cnt;
  logic prevwhns;
  logic prevawhns;


  // Output default
  assign rresp_o = `AXI_RESP_DECERR;
  assign rdata_o = `AXI_DATA_BITS'h0;
  assign rlast_o = cnt == arlen;
  assign bresp_o = `AXI_RESP_DECERR;
  assign rid_o   = arid;
  assign bid_o   = awid_i;

  always_ff @(posedge clk or negedge rst) begin
    if (~rst) begin
      arid  <= `AXI_IDS_BITS'h0;
      arlen <= `AXI_LEN_BITS'h0;
    end else begin
      arid  <= arhns ? arid_i : arid;
      arlen <= arhns ? arlen_i : arlen;
    end
  end


  always_ff @(posedge clk or negedge rst) begin
    STATE <= ~rst ? IDLE : NEXT;
  end

  always_comb begin
    case (STATE)
      IDLE: NEXT = (awvalid_i) ? WRITE : (arvalid_i) ? READ : IDLE;
      READ:
      NEXT = (rhns & rlast_o) ? ((awvalid_i) ? WRITE : (arvalid_i) ? READ : IDLE) : READ;
      WRITE:
      NEXT = (bhns & wlast_i) ? ((awvalid_i) ? WRITE : (arvalid_i) ? READ : IDLE) : WRITE;
      default: NEXT = STATE;
    endcase
  end
  logic read, write;
  always_comb begin
    case (STATE)
      IDLE:    {read, write} = 2'b0;
      READ:    {read, write} = 2'b10;
      WRITE:   {read, write} = 2'b1;
      default: {read, write} = 2'b0;
    endcase
  end
  always_comb begin
    case (STATE)
      IDLE: begin
        awready_o = 1'b1;
        arready_o = ~awvalid_i;
        wready_o  = 1'b1;
      end
      READ: begin
        awready_o = rlast_o & rhns;
        arready_o = rlast_o & rhns & ~awvalid_i;
        wready_o  = rlast_o & rhns;
      end
      WRITE: begin
        awready_o = wlast_i & bhns;
        arready_o = wlast_i & bhns & ~awvalid_i;
        wready_o  = bhns;
      end
      default: begin
        awready_o = 1'b0;
        arready_o = 1'b0;
        wready_o  = 1'b0;
      end
    endcase
  end

  always_comb begin
    case (STATE)
      IDLE: begin
        rvalid_o = 1'b0;
        bvalid_o = 1'b0;
      end
      READ: begin
        rvalid_o = 1'b1;
        bvalid_o = 1'b0;
      end
      WRITE: begin
        rvalid_o = 1'b0;
        bvalid_o = prevwhns;
      end
      default: begin
        rvalid_o = 1'b0;
        bvalid_o = 1'b0;
      end
    endcase
  end

  always_ff @(posedge clk or negedge rst) begin
    if (~rst) cnt <= `AXI_LEN_BITS'b0;
    else if (read)
      cnt <= (rlast_o & rhns) ? `AXI_LEN_BITS'h0 : (rhns) ? cnt + `AXI_LEN_BITS'h1 : cnt;
    else if (write)
      cnt <= (wlast_i & bhns) ? `AXI_LEN_BITS'h0 : (bhns) ? cnt + `AXI_LEN_BITS'h1 : cnt;
  end

  always_ff @(posedge clk or negedge rst) begin
    if (~rst) prevwhns <= 1'b0;
    else prevwhns <= (bhns) ? 1'b0 : (whns) ? 1'b1 : prevwhns;
  end





endmodule
