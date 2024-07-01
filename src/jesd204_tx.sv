module jesd204_tx #(
  parameter BASE_ADDR = 32'h0000_A000,
  parameter LANES     = 1              // four lanes max
) (
  input                        PCLK   ,
  input                        PRESETn,
  input  [     31:0]           PADDR  ,
  input  [      2:0]           PPROT  ,
  input                        PNSE   ,
  input                        PSEL   ,
  input                        PENABLE,
  input                        PWRITE ,
  input  [     31:0]           PWDATA ,
  input  [      3:0]           PSTRB  ,
  output                       PREADY ,
  output [     31:0]           PRDATA ,
  output                       PSLVERR,
  input                        PWAKEUP,
  input  [      7:0]           PAUSER ,
  input  [      7:0]           PWUSER ,
  output [      7:0]           PRUSER ,
  output [      7:0]           PBUSER ,
  input                        CLK    ,
  input                        RST_n  ,
  input                        SYNC_n ,
  input                        SYSREF ,
  output                       RDY    ,
  input  [LANES-1:0][3:0][7:0] DI     ,
  output [LANES-1:0][3:0][7:0] DO
);

  logic            load_setup;
  logic [3:0]      adjcnt    ;
  logic            adjdir    ;
  logic [3:0]      bid       ;
  logic [4:0]      cf        ;
  logic [1:0]      cs        ;
  logic [7:0]      did       ;
  logic [7:0]      f         ;
  logic            hd        ;
  logic [2:0]      jesdv     ;
  logic [4:0]      k         ;
  logic [4:0]      l         ;
  logic [3:0][4:0] lid       ;
  logic [7:0]      m         ;
  logic [4:0]      n         ;
  logic [4:0]      n_        ;
  logic            phadj     ;
  logic [4:0]      s         ;
  logic            scr       ;
  logic [2:0]      subclassv ;
  logic [7:0]      res1      ;
  logic [7:0]      res2      ;
  logic [7:0]      chksum    ;
  logic            en_ila_cnt;
  logic [7:0]      num_ilas  ;
  logic [7:0]      ila_delay ;
  logic [3:0]      lane_en   ;

  apb_regmap #(
    .APB_ADDR_WIDTH      (32       ),
    .APB_DATA_WIDTH_BYTES(4        ),
    .BASE_ADDR           (BASE_ADDR)
  ) regmap (
    .PCLK      (PCLK      ),
    .PRESETn   (PRESETn   ),
    .PADDR     (PADDR     ),
    .PPROT     (PPROT     ),
    .PNSE      (PNSE      ),
    .PSEL      (PSEL      ),
    .PENABLE   (PENABLE   ),
    .PWRITE    (PWRITE    ),
    .PWDATA    (PWDATA    ),
    .PSTRB     (PSTRB     ),
    .PREADY    (PREADY    ),
    .PRDATA    (PRDATA    ),
    .PSLVERR   (PSLVERR   ),
    .PWAKEUP   (PWAKEUP   ),
    .PAUSER    (PAUSER    ),
    .PWUSER    (PWUSER    ),
    .PRUSER    (PRUSER    ),
    .PBUSER    (PBUSER    ),
    .LOAD_SETUP(load_setup),
    .ADJCNT    (adjcnt    ),
    .ADJDIR    (adjdir    ),
    .BID       (bid       ),
    .CF        (cf        ),
    .CS        (cs        ),
    .DID       (did       ),
    .F         (f         ),
    .HD        (hd        ),
    .JESDV     (jesdv     ),
    .K         (k         ),
    .L         (l         ),
    .LID       (lid       ),
    .M         (m         ),
    .N         (n         ),
    .N_        (n_        ),
    .PHADJ     (phadj     ),
    .S         (s         ),
    .SCR       (scr       ),
    .SUBCLASSV (subclassv ),
    .RES1      (res1      ),
    .RES2      (res2      ),
    .CHKSUM    (chksum    ),
    .EN_ILA_CNT(en_ila_cnt),
    .NUM_ILAS  (num_ilas  ),
    .ILA_DELAY (ila_delay ),
    .LANE_EN   (lane_en   )
  );

  logic [1:0] load_setup_cdc;

  // CDC
  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      load_setup_cdc <= {2{1'b0}};
    else
      load_setup_cdc <= {load_setup_cdc[0], load_setup};

  tx #(LANES) tx_ (
    .CLK       (CLK              ),
    .RST_n     (RST_n            ),
    .LOAD_SETUP(load_setup_cdc[1]),
    .ADJCNT    (adjcnt           ),
    .ADJDIR    (adjdir           ),
    .BID       (bid              ),
    .CF        (cf               ),
    .CS        (cs               ),
    .DID       (did              ),
    .F         (f                ),
    .HD        (hd               ),
    .JESDV     (jesdv            ),
    .K         (k                ),
    .L         (l                ),
    .LID       (lid              ),
    .M         (m                ),
    .N         (n                ),
    .N_        (n_               ),
    .PHADJ     (phadj            ),
    .S         (s                ),
    .SCR       (scr              ),
    .SUBCLASSV (subclassv        ),
    .RES1      (res1             ),
    .RES2      (res2             ),
    .CHKSUM    (chksum           ),
    .LANE_EN   (lane_en          ),
    .EN_ILA_CNT(en_ila_cnt       ),
    .NUM_ILAS  (num_ilas         ),
    .ILA_DELAY (ila_delay        ),
    .RDY       (RDY              ),
    .DI        (DI               ),
    .DO        (DO               ),
    .SYNC_n    (SYNC_n           ),
    .SYSREF    (SYSREF           )
  );

endmodule