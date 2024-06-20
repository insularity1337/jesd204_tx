module apb_wo_reg #(
  parameter                            APB_ADDR_WIDTH       = 32 ,
  parameter                            APB_DATA_WIDTH_BYTES = 4  ,
  parameter                            APB_USER_REQ_WIDTH   = 8  ,
  parameter                            APB_USER_RESP_WIDTH  = 8  ,
  parameter logic [APB_ADDR_WIDTH-1:0] ADDR                 = 'b0
) (
  // APB interface
  input                                          PCLK   ,
  input                                          PRESETn,
  input        [        APB_ADDR_WIDTH-1:0]      PADDR  ,
  input        [                       2:0]      PPROT  ,
  input                                          PNSE   ,
  input                                          PSEL   ,
  input                                          PENABLE,
  input                                          PWRITE ,
  input        [      APB_DATA_WIDTH*8-1:0]      PWDATA ,
  input        [  APB_DATA_WIDTH_BYTES-1:0]      PSTRB  ,
  output logic                                   PREADY ,
  output logic [APB_DATA_WIDTH_BYTES*8-1:0]      PRDATA ,
  output logic                                   PSLVERR,
  input                                          PWAKEUP,
  input        [    APB_USER_REQ_WIDTH-1:0]      PAUSER ,
  input        [ APB_USER_DATA_WIDTH*8-1:0]      PWUSER ,
  output logic [ APB_USER_DATA_WIDTH*8-1:0]      PRUSER ,
  output logic [   APB_USER_RESP_WIDTH-1:0]      PBUSER ,
  // Data interface
  output logic                                   DVO    ,
  output logic [  APB_DATA_WIDTH_BYTES-1:0][7:0] DO
);

  for (genvar i = 0; i < APB_DATA_WIDTH_BYTES; i++)
    always_ff @(posedge PCLK)
      if ((PADDR == ADDR) && PSEL && PENABLE && PWRITE && PSTRB[i] && PREADY)
        DO[i] <= PWDATA[i];

  always_ff @(negedge PRESETn, posedge PCLK)
    if (!PRESETn)
      DVO <= 1'b0;
    else if ((PADDR == ADDR) && PSEL && PENABLE && PWRITE && PREADY)
      DVO <= 1'b1;
    else
      DVO <= 1'b0;

endmodule