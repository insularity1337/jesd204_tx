module jesd204_tx_env #(parameter LANES = 4) (
  input                    PCLK       ,
  input                    PRESETn    ,
  input  [     31:0]       PADDR      ,
  input  [      2:0]       PPROT      ,
  input                    PNSE       ,
  input                    PSEL       ,
  input                    PENABLE    ,
  input                    PWRITE     ,
  input  [     31:0]       PWDATA     ,
  input  [      3:0]       PSTRB      ,
  output                   PREADY     ,
  output [     31:0]       PRDATA     ,
  output                   PSLVERR    ,
  input                    PWAKEUP    ,
  input  [      7:0]       PAUSER     ,
  input  [      7:0]       PWUSER     ,
  output [      7:0]       PRUSER     ,
  output [      7:0]       PBUSER     ,
  input                    SYNC_n     ,
  input                    SYSREF     ,
  input                    CLK        ,
  output                   RDY        ,
  input  [LANES-1:0][31:0] DI         ,
  input                    QPLL_REFCLK,
  input                    DRPCLK     ,
  output [LANES-1:0]       TX_N       ,
  output [LANES-1:0]       TX_P
);

  logic phy_rst         ;
  logic phy_rst_done    ;
  logic phy_rst_done_cdc;

  logic [LANES-1:0][3:0][7:0] tx_data  ;
  logic [LANES-1:0][3:0]      tx_data_k;

  jesd204_tx #(LANES) core (
    .PCLK        (PCLK        ),
    .PRESETn     (PRESETn     ),
    .PADDR       (PADDR       ),
    .PPROT       (PPROT       ),
    .PNSE        (PNSE        ),
    .PSEL        (PSEL        ),
    .PENABLE     (PENABLE     ),
    .PWRITE      (PWRITE      ),
    .PWDATA      (PWDATA      ),
    .PSTRB       (PSTRB       ),
    .PREADY      (PREADY      ),
    .PRDATA      (PRDATA      ),
    .PSLVERR     (PSLVERR     ),
    .PWAKEUP     (PWAKEUP     ),
    .PAUSER      (PAUSER      ),
    .PWUSER      (PWUSER      ),
    .PRUSER      (PRUSER      ),
    .PBUSER      (PBUSER      ),
    .PHY_RST     (phy_rst     ),
    .PHY_RST_DONE(phy_rst_done),
    .CLK         (CLK         ),
    .RST_n       (phy_rst_done),
    .SYNC_n      (SYNC_n      ),
    .SYSREF      (SYSREF      ),
    .RDY         (RDY         ),
    .DI          (DI          ),
    .DO_K        (tx_data_k   ),
    .DO          (tx_data     )
  );

  xpm_cdc_single #(
    .DEST_SYNC_FF  (2),
    .INIT_SYNC_FF  (1),
    .SIM_ASSERT_CHK(1),
    .SRC_INPUT_REG (0)
  ) phy_done_cdc (
    .src_clk (CLK             ),
    .src_in  (phy_rst_done    ),
    .dest_out(phy_rst_done_cdc),
    .dest_clk(PCLK            )
  );

  jesd204b_tx_phy phy (
    .qpll0_refclk            (QPLL_REFCLK ),
    .drpclk                  (DRPCLK      ),
    .tx_reset_gt             (phy_rst     ),
    .rx_reset_gt             (phy_rst     ),
    .tx_sys_reset            (phy_rst     ),
    .rx_sys_reset            (phy_rst     ),
    .txp_out                 (TX_P        ),
    .txn_out                 (TX_N        ),
    .rxp_in                  (1'b0        ),
    .rxn_in                  (1'b0        ),
    .tx_core_clk             (CLK         ),
    .rx_core_clk             (CLK         ),
    .txoutclk                (txoutclk    ),
    .rxoutclk                (rxoutclk    ),
    .gt_prbssel              (4'h0        ),
    .gt0_txdata              (tx_data[0]  ),
    .gt0_txcharisk           (tx_data_k[0]),
    .gt1_txdata              (tx_data[1]  ),
    .gt1_txcharisk           (tx_data_k[1]),
    .gt2_txdata              (tx_data[2]  ),
    .gt2_txcharisk           (tx_data_k[2]),
    .gt3_txdata              (tx_data[3]  ),
    .gt3_txcharisk           (tx_data_k[3]),
    .tx_reset_done           (phy_rst_done),
    .gt_powergood            (            ),
    .gt0_rxdata              (            ),
    .gt0_rxcharisk           (            ),
    .gt0_rxdisperr           (            ),
    .gt0_rxnotintable        (            ),
    .gt1_rxdata              (            ),
    .gt1_rxcharisk           (            ),
    .gt1_rxdisperr           (            ),
    .gt1_rxnotintable        (            ),
    .gt2_rxdata              (            ),
    .gt2_rxcharisk           (            ),
    .gt2_rxdisperr           (            ),
    .gt2_rxnotintable        (            ),
    .gt3_rxdata              (            ),
    .gt3_rxcharisk           (            ),
    .gt3_rxdisperr           (            ),
    .gt3_rxnotintable        (            ),
    .rx_reset_done           (            ),
    .rxencommaalign          (1'b0        ),
    .common0_qpll0_clk_out   (            ),
    .common0_qpll0_refclk_out(            ),
    .common0_qpll0_lock_out  (            )
  );

endmodule