module tx #(parameter LANES = 1) (
  input                              CLK       ,
  input                              RST_n     ,
  input                              LOAD_SETUP,
  // Configuration
  input        [      3:0]           ADJCNT    ,
  input                              ADJDIR    ,
  input        [      3:0]           BID       ,
  input        [      4:0]           CF        ,
  input        [      1:0]           CS        ,
  input        [      7:0]           DID       ,
  input        [      7:0]           F         ,
  input                              HD        ,
  input        [      2:0]           JESDV     , // b only
  input        [      4:0]           K         ,
  input        [      4:0]           L         ,
  input        [LANES-1:0][4:0]      LID       ,
  input        [      7:0]           M         ,
  input        [      4:0]           N         ,
  input        [      4:0]           N_        ,
  input                              PHADJ     ,
  input        [      4:0]           S         ,
  input                              SCR       ,
  input        [      2:0]           SUBCLASSV , // 0 & 1
  input        [      7:0]           RES1      ,
  input        [      7:0]           RES2      ,
  input        [      7:0]           CHKSUM    ,
  // Optional configuration
  input        [LANES-1:0]           LANE_EN   ,
  input                              EN_ILA_CNT, // Replace zeroes with counter inside ILA multiframes
  input        [      7:0]           NUM_ILAS  ,
  input        [      7:0]           ILA_DELAY ,
  // Input data interface
  output logic                       RDY       ,
  input        [LANES-1:0][3:0][7:0] DI        ,
  output       [LANES-1:0][3:0][7:0] DO        ,
  // Synchronization interface
  input                              SYNC_n    ,
  input                              SYSREF
);

  logic             lmfc_synced;
  logic             lmfc_en    ;
  logic [LANES-1:0] ila_en     ;

  logic [3:0] fs, fe, ms, me;

  logic [LANES-1:0]           ila_rdy      ;
  logic [LANES-1:0][3:0][7:0] ila_di       ;
  logic [LANES-1:0][3:0]      post_ila_fs, post_ila_fe;
  logic [LANES-1:0][3:0]      post_ila_ms, post_ila_me;
  logic [LANES-1:0][3:0][7:0] post_ila_data;

  logic [LANES-1:0] char_en;

  /*  Control unit
   */
  tx_cu #(LANES) cu (
    .CLK        (CLK        ),
    .RST_n      (RST_n      ),
    .LANE_EN    (LANE_EN    ),
    .ILA_DELAY  (ILA_DELAY  ),
    .SUBCLASSV  (SUBCLASSV  ),
    .SYNC       (SYNC_n     ),
    .LMFC_SYNCED(lmfc_synced),
    .LMFC_MS    (ms         ),
    .LMFC_ME    (me         ),
    .LMFC_EN    (lmfc_en    ),
    .ILA_ME     (post_ila_me),
    .ILA_RDY    (ila_rdy    ),
    .ILA_EN     (ila_en     ),
    .CHAR_EN    (char_en    )
  );

  tx_lmfc lmfc_gen (
    .CLK       (CLK        ),
    .RST_n     (RST_n      ),
    .SUBCLASSV (SUBCLASSV  ),
    .EN        (lmfc_en    ),
    .SYSREF    (SYSREF     ),
    .LOAD_SETUP(LOAD_SETUP ),
    .L         (L          ),
    .F         (F          ),
    .K         (K          ),
    .MS        (ms         ),
    .ME        (me         ),
    .FS        (fs         ),
    .FE        (fe         ),
    .SYNCED    (lmfc_synced)
  );

  for (genvar i = 0; i < LANES; i++) begin

    for (genvar j = 0; j < 4; j++)
      always_comb
        if (ila_rdy[i])
          ila_di[i][j] = DI[i][j];
        else
          ila_di[i][j] = 8'b10111100; // K28.5

    tx_ila_gen ila_gen (
      .CLK       (CLK             ),
      .RST_n     (RST_n           ),
      .EN        (ila_en[i]       ),
      .FE        (fe              ),
      .FS        (fs              ),
      .MS        (ms              ),
      .ME        (me              ),
      .DI        (ila_di[i]       ),
      .NUM_ILAS  (NUM_ILAS        ),
      .EN_CNT    (EN_ILA_CNT      ),
      .LOAD_SETUP(LOAD_SETUP      ),
      .ADJCNT    (ADJCNT          ),
      .ADJDIR    (ADJDIR          ),
      .BID       (BID             ),
      .CF        (CF              ),
      .CS        (CS              ),
      .DID       (DID             ),
      .F         (F               ),
      .HD        (HD              ),
      .JESDV     (JESDV           ),
      .K         (K               ),
      .L         (L               ),
      .LID       (LID[i]          ),
      .M         (M               ),
      .N         (N               ),
      .N_        (N_              ),
      .PHADJ     (PHADJ           ),
      .S         (S               ),
      .SCR       (SCR             ),
      .SUBCLASSV (SUBCLASSV       ),
      .RES1      (RES1            ),
      .RES2      (RES2            ),
      .CHKSUM    (CHKSUM          ),
      .FS_OUT    (post_ila_fs[i]  ),
      .FE_OUT    (post_ila_fe[i]  ),
      .MS_OUT    (post_ila_ms[i]  ),
      .ME_OUT    (post_ila_me[i]  ),
      .RDY       (ila_rdy[i]      ),
      .DO        (post_ila_data[i])
    );

    tx_char_replace tx_char_rep (
      .CLK  (CLK             ),
      .RST_n(RST_n           ),
      .EN   (char_en[i]      ),
      .F    (F               ),
      .FE   (post_ila_fe[i]  ),
      .ME   (post_ila_me[i]  ),
      .DI   (post_ila_data[i]),
      .DO   (DO[i]           )
    );
  end

  always_comb
    RDY = |ila_rdy;

endmodule