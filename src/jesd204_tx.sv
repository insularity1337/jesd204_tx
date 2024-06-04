module jesd204_tx #(parameter LANES = 1) (
  input                              PCLK        ,
  input                              PRESETn     ,
  input        [     31:0]           PADDR       ,
  input        [      2:0]           PPROT       ,
  input                              PNSE        ,
  input                              PSEL        ,
  input                              PENABLE     ,
  input                              PWRITE      ,
  input        [     31:0]           PWDATA      ,
  input        [      3:0]           PSTRB       ,
  output                             PREADY      ,
  output       [     31:0]           PRDATA      ,
  output                             PSLVERR     ,
  input                              PWAKEUP     ,
  input        [      7:0]           PAUSER      ,
  input        [      7:0]           PWUSER      ,
  output       [      7:0]           PRUSER      ,
  output       [      7:0]           PBUSER      ,
  output logic                       PHY_RST     ,
  input                              PHY_RST_DONE,
  input                              CLK         ,
  input                              RST_n       ,
  input                              SYNC_n      ,
  input                              SYSREF      ,
  output                             RDY         ,
  input        [LANES-1:0][3:0][7:0] DI          ,
  output       [LANES-1:0][3:0]      DO_K        ,
  output       [LANES-1:0][3:0][7:0] DO
);

  jesd204b_reg_pkg::jesd204b_reg__in_t  regmap_hw_in ;
  jesd204b_reg_pkg::jesd204b_reg__out_t regmap_hw_out;

  logic regmap_tx_reset;
  logic tx_reset;

  always_comb begin
    regmap_hw_in.PRESETn = PRESETn;
    regmap_hw_in.PHY_RESET_DONE.DONE.next = PHY_RST_DONE;
  end

  always_comb begin
    PHY_RST = regmap_hw_out.PHY_RESET.RST.value;
  end

  jesd204b_reg regmap (
    .clk          (PCLK         ),
    .s_apb_psel   (PSEL         ),
    .s_apb_penable(PENABLE      ),
    .s_apb_pwrite (PWRITE       ),
    .s_apb_pprot  (PPROT        ),
    .s_apb_paddr  (PADDR        ),
    .s_apb_pwdata (PWDATA       ),
    .s_apb_pstrb  (PSTRB        ),
    .s_apb_pready (PREADY       ),
    .s_apb_prdata (PRDATA       ),
    .s_apb_pslverr(PSLVERR      ),
    .hwif_in      (regmap_hw_in ),
    .hwif_out     (regmap_hw_out)
  );

  xpm_cdc_sync_rst #(
    .DEST_SYNC_FF  (2),
    .INIT          (0),
    .INIT_SYNC_FF  (1),
    .SIM_ASSERT_CHK(1)
  ) tx_reset_cdc (
    .src_rst (regmap_hw_out.RESET.RST.value),
    .dest_clk(CLK                          ),
    .dest_rst(regmap_tx_reset              )
  );

  always_comb
    tx_reset = regmap_tx_reset & RST_n;

  tx #(LANES) tx_ (
    .CLK       (CLK                                     ),
    .RST_n     (tx_reset                                ),
    .ADJCNT    (regmap_hw_out.LINK_CFG_0.ADJCNT.value   ),
    .ADJDIR    (regmap_hw_out.LINK_CFG_0.ADJDIR.value   ),
    .BID       (regmap_hw_out.LINK_CFG_0.BID.value      ),
    .CF        (regmap_hw_out.LINK_CFG_0.CF.value       ),
    .CS        (regmap_hw_out.LINK_CFG_0.CS.value       ),
    .DID       (regmap_hw_out.LINK_CFG_0.DID.value      ),
    .F         (regmap_hw_out.LINK_CFG_0.F.value        ),
    .HD        (regmap_hw_out.LINK_CFG_1.HD.value       ),
    .JESDV     (regmap_hw_out.LINK_CFG_1.JESDV.value    ),
    .K         (regmap_hw_out.LINK_CFG_1.K.value        ),
    .L         (regmap_hw_out.LINK_CFG_1.L.value        ),
    .LID       ({regmap_hw_out.LID_3.LID.value,
                 regmap_hw_out.LID_2.LID.value,
                 regmap_hw_out.LID_1.LID.value,
                 regmap_hw_out.LID_0.LID.value}         ),
    .M         (regmap_hw_out.LINK_CFG_1.M.value        ),
    .N         (regmap_hw_out.LINK_CFG_1.N.value        ),
    .N_        (regmap_hw_out.LINK_CFG_2.N_.value       ),
    .PHADJ     (regmap_hw_out.LINK_CFG_2.PHADJ.value    ),
    .S         (regmap_hw_out.LINK_CFG_2.S.value        ),
    .SCR       (regmap_hw_out.LINK_CFG_2.SCR.value      ),
    .SUBCLASSV (regmap_hw_out.LINK_CFG_2.SUBCLASSV.value),
    .RES1      (regmap_hw_out.LINK_CFG_2.RES1.value     ),
    .RES2      (regmap_hw_out.LINK_CFG_2.RES2.value     ),
    .CHCKSUM   ({regmap_hw_out.CHCKSUM_3.CHCKSUM.value,
                 regmap_hw_out.CHCKSUM_2.CHCKSUM.value,
                 regmap_hw_out.CHCKSUM_1.CHCKSUM.value,
                 regmap_hw_out.CHCKSUM_0.CHCKSUM.value} ),
    .LANE_EN   ({regmap_hw_out.LANE_EN.LANE_3_EN.value,
                 regmap_hw_out.LANE_EN.LANE_2_EN.value,
                 regmap_hw_out.LANE_EN.LANE_1_EN.value,
                 regmap_hw_out.LANE_EN.LANE_0_EN.value} ),
    .EN_ILA_CNT(regmap_hw_out.ILA_CFG.EN_ILA_CNT.value  ),
    .NUM_ILAS  (regmap_hw_out.ILA_CFG.NUM_ILAS.value    ),
    .ILA_DELAY (regmap_hw_out.ILA_CFG.ILA_DELAY.value   ),
    .RDY       (RDY                                     ),
    .DI        (DI                                      ),
    .DO_K      (DO_K                                    ),
    .DO        (DO                                      ),
    .SYNC_n    (SYNC_n                                  ),
    .SYSREF    (SYSREF                                  )
  );

endmodule