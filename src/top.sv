module top (
  input        REFCLK_P,
  input        REFCLK_N,
  input        DRPCLK  ,
  input        CLK     ,
  input        SYNC_n  ,
  input        SYSREF  ,
  output [3:0] TX_N    ,
  output [3:0] TX_P
);

  logic        pclk   ;
  logic        presetn;
  logic [31:0] paddr  ;
  logic        penable;
  logic [ 2:0] pprot  ;
  logic [31:0] prdata ;
  logic [ 0:0] pready ;
  logic [ 0:0] psel   ;
  logic [ 0:0] pslverr;
  logic [ 3:0] pstrb  ;
  logic [31:0] pwdata ;
  logic        pwrite ;

  logic qpll_refclk;

  logic                 rdy;
  logic [3:0][3:0][7:0] di  = '{
    {8'h0F, 8'h0E, 8'h0D, 8'h0C},
    {8'h0B, 8'h0A, 8'h09, 8'h08},
    {8'h07, 8'h06, 8'h05, 8'h04},
    {8'h03, 8'h02, 8'h01, 8'h00}
  };

  ctrl_n_data_env_wrapper bd (
    .CLK        (DRPCLK ),
    .PCLK       (pclk   ),
    .PRESETn    (presetn),
    .APB_paddr  (paddr  ),
    .APB_penable(penable),
    .APB_pprot  (pprot  ),
    .APB_prdata (prdata ),
    .APB_pready (pready ),
    .APB_psel   (psel   ),
    .APB_pslverr(pslverr),
    .APB_pstrb  (pstrb  ),
    .APB_pwdata (pwdata ),
    .APB_pwrite (pwrite )
  );

  IBUFDS refclk_d2s (
    .O (qpll_refclk),
    .I (REFCLK_P   ),
    .IB(REFCLK_N   )
  );

  for (genvar i = 0; i < 4; i++)
    for (genvar j = 0; j < 4; j++)
      always_ff @(posedge CLK)
        if (rdy)
          di[i][j] <= di[i][j] + 16;

  jesd204_tx_env #(4) jesd204_tx (
    .PCLK       (pclk       ),
    .PRESETn    (presetn    ),
    .PADDR      (paddr      ),
    .PPROT      (pprot      ),
    .PNSE       (1'b0       ),
    .PSEL       (psel       ),
    .PENABLE    (penable    ),
    .PWRITE     (pwrite     ),
    .PWDATA     (pwdata     ),
    .PSTRB      (pstrb      ),
    .PREADY     (pready     ),
    .PRDATA     (prdata     ),
    .PSLVERR    (pslverr    ),
    .PWAKEUP    (1'b1       ),
    .PAUSER     (8'h00      ),
    .PWUSER     (8'h00      ),
    .PRUSER     (8'h00      ),
    .PBUSER     (8'h00      ),
    .SYNC_n     (SYNC_n     ),
    .SYSREF     (SYSREF     ),
    .CLK        (CLK        ),
    .RDY        (rdy        ),
    .DI         (di         ),
    .QPLL_REFCLK(qpll_refclk),
    .DRPCLK     (DRPCLK     ),
    .TX_N       (TX_N       ),
    .TX_P       (TX_P       )
  );

endmodule