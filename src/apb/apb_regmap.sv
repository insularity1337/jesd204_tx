module apb_regmap #(
  parameter                            APB_ADDR_WIDTH       = 32 ,
  parameter                            APB_DATA_WIDTH_BYTES = 4  ,
  parameter                            APB_USER_REQ_WIDTH   = 8  ,
  parameter                            APB_USER_RESP_WIDTH  = 8  ,
  parameter logic [APB_ADDR_WIDTH-1:0] BASE_ADDR            = 'b0,
  parameter                            SIZE                 = 8
) (
  // APB interface
  input                                     PCLK      ,
  input                                     PRESETn   ,
  input        [        APB_ADDR_WIDTH-1:0] PADDR     ,
  input        [                       2:0] PPROT     ,
  input                                     PNSE      ,
  input                                     PSEL      ,
  input                                     PENABLE   ,
  input                                     PWRITE    ,
  input        [      APB_DATA_WIDTH*8-1:0] PWDATA    ,
  input        [  APB_DATA_WIDTH_BYTES-1:0] PSTRB     ,
  output logic                              PREADY    ,
  output logic [APB_DATA_WIDTH_BYTES*8-1:0] PRDATA    ,
  output logic                              PSLVERR   ,
  input                                     PWAKEUP   ,
  input        [    APB_USER_REQ_WIDTH-1:0] PAUSER    ,
  input        [ APB_USER_DATA_WIDTH*8-1:0] PWUSER    ,
  output logic [ APB_USER_DATA_WIDTH*8-1:0] PRUSER    ,
  output logic [   APB_USER_RESP_WIDTH-1:0] PBUSER    ,
  // APB <-> JESD
  output                                    LOAD_SETUP,
  output       [                       3:0] ADJCNT    ,
  output                                    ADJDIR    ,
  output       [                       3:0] BID       ,
  output       [                       4:0] CF        ,
  output       [                       1:0] CS        ,
  output       [                       7:0] DID       ,
  output       [                       7:0] F         ,
  output                                    HD        ,
  output       [                       2:0] JESDV     ,
  output       [                       4:0] K         ,
  output       [                       4:0] L         ,
  output       [                       4:0] LID       ,
  output       [                       7:0] M         ,
  output       [                       4:0] N         ,
  output       [                       4:0] N_        ,
  output                                    PHADJ     ,
  output       [                       4:0] S         ,
  output                                    SCR       ,
  output       [                       2:0] SUBCLASSV ,
  output       [                       7:0] RES1      ,
  output       [                       7:0] RES2      ,
  output       [                       7:0] CHKSUM    ,
  output                                    EN_ILA_CNT,
  output       [                       7:0] NUM_ILAS  ,
  output       [                       7:0] ILA_DELAY ,
);

  logic psel;

  always_comb begin
    if ((PADDR[APB_ADDR_WIDTH-1:$clog2(SIZE)+2] == BASE_ADDR[APB_ADDR_WIDTH-1:$clog2(SIZE)+2]) && PSEL)
      psel = 1'b1;
    else
      psel = 1'b0;
  end

  logic [3:0]                             link_conf_valid;
  logic [3:0][APB_DATA_WIDTH_BYTES*8-1:0] link_conf      ;
  logic [3:0]                             link_conf_rdy  ;
  logic [3:0][APB_DATA_WIDTH_BYTES*8-1:0] link_conf_rdata;

  for (genvar i = 0; i < 4; i++)
    apb_rw_reg #(
      .APB_ADDR_WIDTH      ($clog2(SIZE)+2      ),
      .APB_DATA_WIDTH_BYTES(APB_DATA_WIDTH_BYTES),
      .APB_USER_REQ_WIDTH  (APB_USER_REQ_WIDTH  ),
      .APB_USER_RESP_WIDTH (APB_USER_RESP_WIDTH ),
      .ADDR                (i*4                 )
    ) link_conf_reg (
      .PCLK   (PCLK              ),
      .PRESETn(PRESETn           ),
      .PADDR  (PADDR             ),
      .PPROT  (PPROT             ),
      .PNSE   (PNSE              ),
      .PSEL   (psel              ),
      .PENABLE(PENABLE           ),
      .PWRITE (PWRITE            ),
      .PWDATA (PWDATA            ),
      .PSTRB  (PSTRB             ),
      .PREADY (link_conf_rdy[i]  ),
      .PRDATA (link_conf_rdata[i]),
      .PSLVERR(                  ),
      .PWAKEUP(PWAKEUP           ),
      .PAUSER (PAUSER            ),
      .PWUSER (PWUSER            ),
      .PRUSER (                  ),
      .PBUSER (                  ),
      .DVO    (link_conf_valid[i]),
      .DO     (link_conf[i]      )
    );

  always_comb begin
    F      = link_conf[0][31:24];
    DID    = link_conf[0][23:16];
    CS     = link_conf[0][15:14];
    CF     = link_conf[0][13: 9];
    BID    = link_conf[0][ 8: 5];
    ADJDIR = link_conf[0][    4];
    ADJCNT = link_conf[0][ 3: 0];

    N     = link_conf[1][31:27];
    M     = link_conf[1][26:19];
    LID   = link_conf[1][18:14];
    L     = link_conf[1][13: 9];
    K     = link_conf[1][ 8: 4];
    JESDV = link_conf[1][ 3: 1];
    HD    = link_conf[1][    0];

    RES2      = link_conf[2][30:23];
    RES1      = link_conf[2][22:15];
    SUBCLASSV = link_conf[2][14:12];
    SCR       = link_conf[2][   11];
    S         = link_conf[2][10: 6];
    PHADJ     = link_conf[2][    5];
    N_        = link_conf[2][ 4: 0];

    CHKSUM = link_conf[3][7:0];
  end

  logic                              ila_conf_valid;
  logic [APB_DATA_WIDTH_BYTES*8-1:0] ila_conf      ;
  logic                              ila_conf_rdy  ;
  logic [APB_DATA_WIDTH_BYTES*8-1:0] ila_conf_rdata;

  apb_rw_reg #(
    .APB_ADDR_WIDTH      ($clog2(SIZE)+2      ),
    .APB_DATA_WIDTH_BYTES(APB_DATA_WIDTH_BYTES),
    .APB_USER_REQ_WIDTH  (APB_USER_REQ_WIDTH  ),
    .APB_USER_RESP_WIDTH (APB_USER_RESP_WIDTH ),
    .ADDR                (4*4                 )
  ) ila_conf_reg (
    .PCLK   (PCLK          ),
    .PRESETn(PRESETn       ),
    .PADDR  (PADDR         ),
    .PPROT  (PPROT         ),
    .PNSE   (PNSE          ),
    .PSEL   (psel          ),
    .PENABLE(PENABLE       ),
    .PWRITE (PWRITE        ),
    .PWDATA (PWDATA        ),
    .PSTRB  (PSTRB         ),
    .PREADY (ila_conf_rdy  ),
    .PRDATA (ila_conf_rdata),
    .PSLVERR(              ),
    .PWAKEUP(PWAKEUP       ),
    .PAUSER (PAUSER        ),
    .PWUSER (PWUSER        ),
    .PRUSER (              ),
    .PBUSER (              ),
    .DVO    (ila_conf_valid),
    .DO     (ila_conf      )
  );

  always_comb begin
    EN_ILA_CNT = ila_conf[   16];
    ILA_DELAY  = ila_conf[15: 8];
    NUM_ILAS   = ila_conf[ 7: 0];
  end

  logic                              load_conf_valid;
  logic [APB_DATA_WIDTH_BYTES*8-1:0] load_conf      ;
  logic                              load_conf_rdy  ;
  logic [APB_DATA_WIDTH_BYTES*8-1:0] load_conf_rdata;

  apb_rw_reg #(
    .APB_ADDR_WIDTH      ($clog2(SIZE)+2      ),
    .APB_DATA_WIDTH_BYTES(APB_DATA_WIDTH_BYTES),
    .APB_USER_REQ_WIDTH  (APB_USER_REQ_WIDTH  ),
    .APB_USER_RESP_WIDTH (APB_USER_RESP_WIDTH ),
    .ADDR                (5*4                 )
  ) load_conf_reg (
    .PCLK   (PCLK           ),
    .PRESETn(PRESETn        ),
    .PADDR  (PADDR          ),
    .PPROT  (PPROT          ),
    .PNSE   (PNSE           ),
    .PSEL   (psel           ),
    .PENABLE(PENABLE        ),
    .PWRITE (PWRITE         ),
    .PWDATA (PWDATA         ),
    .PSTRB  (PSTRB          ),
    .PREADY (load_conf_rdy  ),
    .PRDATA (load_conf_rdata),
    .PSLVERR(               ),
    .PWAKEUP(PWAKEUP        ),
    .PAUSER (PAUSER         ),
    .PWUSER (PWUSER         ),
    .PRUSER (               ),
    .PBUSER (               ),
    .DVO    (load_conf_valid),
    .DO     (load_conf      )
  );

  always_comb begin
    LOAD_SETUP = load_conf_valid & load_conf[0];
  end

  always_comb begin
    PREADY = |link_conf_rdy |
              ila_conf_rdy  |
              load_conf_rdy;

    PRDATA = |link_conf_rdata |
              ila_conf_rdata  |
              load_conf_rdata;
  end

endmodule