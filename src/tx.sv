module tx (
  input             CLK       ,
  input             RST_n     ,
  input             LOAD_SETUP,
  // Configuration
  input  [3:0]      ADJCNT    ,
  input             ADJDIR    ,
  input  [3:0]      BID       ,
  input  [4:0]      CF        ,
  input  [1:0]      CS        ,
  input  [7:0]      DID       ,
  input  [7:0]      F         ,
  input             HD        ,
  input  [2:0]      JESDV     , // b only
  input  [4:0]      K         ,
  input  [4:0]      L         ,
  input  [4:0]      LID       ,
  input  [7:0]      M         ,
  input  [4:0]      N         ,
  input  [4:0]      N_        ,
  input             PHADJ     ,
  input  [4:0]      S         ,
  input             SCR       ,
  input  [2:0]      SUBCLASSV , // 1 only
  input  [7:0]      RES1      ,
  input  [7:0]      RES2      ,
  input  [7:0]      CHKSUM    ,
  // Input data interface
  output            RDY       ,
  input  [3:0][7:0] DI        ,
  output [3:0][7:0] DO        ,
  // Synchronization interface
  input             SYNC_n    ,
  input             SYSREF
);

  logic lmfc_synced;
  logic lmfc_en    ;
  logic ila_en     ;

  logic [3:0] fs, fe, ms, me;

  logic [3:0][7:0] ila_di       ;
  logic [3:0]      post_ila_fs, post_ila_fe;
  logic [3:0]      post_ila_ms, post_ila_me;
  logic [3:0][7:0] post_ila_data;

  logic char_en;

  /*  Control unit
   */
  tx_cu cu (
    .CLK        (CLK        ),
    .RST_n      (RST_n      ),
    .SYNC       (SYNC_n     ),
    .LMFC_SYNCED(lmfc_synced),
    .LMFC_MS    (ms         ),
    .LMFC_ME    (me         ),
    .LMFC_EN    (lmfc_en    ),
    .ILA_ME     (post_ila_me),
    .ILA_RDY    (RDY        ),
    .ILA_EN     (ila_en     ),
    .CHAR_EN    (char_en    )
  );

  tx_lmfc lmfc_gen (
    .CLK       (CLK        ),
    .RST_n     (RST_n      ),
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

  for (genvar i = 0; i < 4; i++)
    always_comb
      if (RDY)
        ila_di[i] = DI[i];
      else
        ila_di[i] = 8'b10111100; // K28.5

  tx_ila_gen ila_gen (
    .CLK       (CLK          ),
    .RST_n     (RST_n        ),
    .EN        (ila_en       ),
    .FE        (fe           ),
    .FS        (fs           ),
    .MS        (ms           ),
    .ME        (me           ),
    .DI        (ila_di       ),
    .LOAD_SETUP(LOAD_SETUP   ),
    .ADJCNT    (ADJCNT       ),
    .ADJDIR    (ADJDIR       ),
    .BID       (BID          ),
    .CF        (CF           ),
    .CS        (CS           ),
    .DID       (DID          ),
    .F         (F            ),
    .HD        (HD           ),
    .JESDV     (JESDV        ), // b only
    .K         (K            ),
    .L         (L            ),
    .LID       (LID          ),
    .M         (M            ),
    .N         (N            ),
    .N_        (N_           ),
    .PHADJ     (PHADJ        ),
    .S         (S            ),
    .SCR       (SCR          ),
    .SUBCLASSV (SUBCLASSV    ), // 1 only
    .RES1      (RES1         ),
    .RES2      (RES2         ),
    .CHKSUM    (CHKSUM       ),
    .FS_OUT    (post_ila_fs  ),
    .FE_OUT    (post_ila_fe  ),
    .MS_OUT    (post_ila_ms  ),
    .ME_OUT    (post_ila_me  ),
    .RDY       (RDY          ),
    .DO        (post_ila_data)
  );

  tx_char_replace tx_char_rep (
    .CLK  (CLK          ),
    .RST_n(RST_n        ),
    .EN   (char_en      ),
    .F    (F            ),
    .FE   (post_ila_fe  ),
    .ME   (post_ila_me  ),
    .DI   (post_ila_data),
    .DO   (DO           )
  );

endmodule