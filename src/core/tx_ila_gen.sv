module tx_ila_gen (
  input                   CLK       ,
  input                   RST_n     ,
  input                   EN        ,
  input        [3:0]      FS        ,
  input        [3:0]      FE        ,
  input        [3:0]      MS        ,
  input        [3:0]      ME        ,
  input        [3:0]      DI_K      ,
  input        [3:0][7:0] DI        ,
  input                   EN_CNT    ,
  input        [7:0]      NUM_ILAS  ,
  // ILA frame #2 data
  input        [3:0]      ADJCNT    ,
  input                   ADJDIR    ,
  input        [3:0]      BID       ,
  input        [4:0]      CF        ,
  input        [1:0]      CS        ,
  input        [7:0]      DID       ,
  input        [7:0]      F         ,
  input                   HD        ,
  input        [2:0]      JESDV     , // b only
  input        [4:0]      K         ,
  input        [4:0]      L         ,
  input        [4:0]      LID       ,
  input        [7:0]      M         ,
  input        [4:0]      N         ,
  input        [4:0]      N_        ,
  input                   PHADJ     ,
  input        [4:0]      S         ,
  input                   SCR       ,
  input        [2:0]      SUBCLASSV , // 1 only
  input        [7:0]      RES1      ,
  input        [7:0]      RES2      ,
  input        [7:0]      CHKSUM    ,
  output logic            RDY       ,
  output logic [3:0]      FS_OUT    ,
  output logic [3:0]      FE_OUT    ,
  output logic [3:0]      MS_OUT    ,
  output logic [3:0]      ME_OUT    ,
  output logic [3:0]      DO_K      ,
  output logic [3:0][7:0] DO
);

  logic            send_ilas        ;
  logic [7:0]      multiframe_cnt   ;
  logic            en               ;
  logic            en_se_replacement;
  logic [3:0]      conf_data        ;
  logic [3:0][7:0] cnt              ;
  logic [3:0][7:0] data             ;

  logic [3:0] k ;
  logic [3:0] k_;

  logic [3:0] fs, fe;
  logic [3:0] me, ms;



  /*  Start genration at the next multiframe boundary
   *  End after NUM_ILAS multiframes generated
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      send_ilas <= 1'b0;
    else if (|ME)
      if (EN && !en)
        send_ilas <= 1'b1;
      else if (multiframe_cnt == NUM_ILAS)
        send_ilas <= 1'b0;

  /*  Generated multiframes counter
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      multiframe_cnt <= 'b0;
    else if (|ME && send_ilas)
      if (multiframe_cnt < NUM_ILAS)
        multiframe_cnt <= multiframe_cnt + 1;
      else
        multiframe_cnt <= 'b0;


  always_ff @(posedge CLK)
    if (!RST_n)
      en <= 1'b0;
    else if (|ME)
      en <= EN;

  always_ff @(posedge CLK)
    if (!RST_n)
      en_se_replacement <= 1'b0;
    else
      en_se_replacement <= send_ilas;

  /*  Configuration data insertion flag
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      conf_data <= 'b0;
    else if (en) begin
      conf_data <= {conf_data[2:0], (|ME & (multiframe_cnt == 0))};
    end else
      conf_data <= 'b0;

  /*  Non-configuration ila data generation
   */
  for (genvar i = 0; i < 4; i++)
    always_ff @(posedge CLK)
      if (!RST_n)
        cnt[i] <= 'b0;
      else if (EN_CNT) begin
        if (EN && !en)
          cnt[i] <= i;
        else
          cnt[i] <= cnt[i] + 4;
      end else
        cnt[i] <= 'b0;

  /*  ILA frame #1 octet #0 link configuration insertion
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      data[0] <= 'b0;
    else if (send_ilas)
      case (conf_data)
        4'b0001: data[0] <= 8'h00;
        4'b0010: data[0] <= {1'b0, ADJDIR, PHADJ, LID};
        4'b0100: data[0] <= M;
        4'b1000: data[0] <= {HD, 2'b00, CF};
        default: data[0] <= cnt[0];
      endcase
    else
      data[0] <= DI[0];

  /*  ILA frame #1 octet #1 link configuration insertion
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      data[1] <= 'b0;
    else if (send_ilas)
      case (conf_data)
        4'b0001: data[1] <= 8'b100_11100; // K28.4
        4'b0010: data[1] <= {SCR, 2'b00, L};
        4'b0100: data[1] <= {CS, 1'b0, N};
        4'b1000: data[1] <= RES1;
        default: data[1] <= cnt[1];
      endcase
    else
      data[1] <= DI[1];

  /*  ILA frame #1 octet #2 link configuration insertion
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      data[2] <= 'b0;
    else if (send_ilas)
      case (conf_data)
        4'b0001: data[2] <= DID;
        4'b0010: data[2] <= F;
        4'b0100: data[2] <= {SUBCLASSV, N_};
        4'b1000: data[2] <= RES2;
        default: data[2] <= cnt[2];
      endcase
    else
      data[2] <= DI[2];

  /*  ILA frame #1 octet #2 link configuration insertion
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      data[3] <= 'b0;
    else if (send_ilas)
      case (conf_data)
        4'b0001: data[3] <= {ADJCNT, BID};
        4'b0010: data[3] <= {3'b000, K};
        4'b0100: data[3] <= {JESDV, S};
        4'b1000: data[3] <= CHKSUM;
        default: data[3] <= cnt[3];
      endcase
    else
      data[3] <= DI[3];

  /*  Local comma octet flags
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      k_ <= {4{1'b0}};
    else if (send_ilas && (conf_data == 4'b0001))
      k_ <= 4'b0010;
    else
      k_ <= {4{1'b0}};

  /*  Delay for external comma octet flags
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      k <= {4{1'b0}};
    else
      k <= DI_K;

  /*  Delay for multi- and frame start & end flags
   */
  always_ff @(posedge CLK)
    if (!RST_n) begin
      fs <= 'b0;
      fe <= 'b0;
      ms <= 'b0;
      me <= 'b0;
    end else begin
      fs <= FS & {4{EN}};
      fe <= FE & {4{EN}};
      ms <= MS & {4{EN}};
      me <= ME & {4{EN}};
    end

  always_ff @(posedge CLK)
    if (!RST_n)
      {FS_OUT, FE_OUT, MS_OUT, ME_OUT} <= 'b0;
    else
      {FS_OUT, FE_OUT, MS_OUT, ME_OUT} <= {fs, fe, ms, me};

  /*  Start & end of frame character replacement
   */
  for (genvar i = 0; i < 4; i++)
    always_ff @(posedge CLK)
      if (!RST_n) begin
        DO[i] <= 'b0;
        DO_K[i] <= 1'b0;
      end else
        case ({en_se_replacement, me[i], ms[i]})

          3'b1_01: begin
            DO[i] <= 8'b000_11100; // /R/
            DO_K[i] <= 1'b1;
          end

          3'b1_10: begin
            DO[i] <= 8'b011_11100; // /A/
            DO_K[i] <= 1'b1;
          end

          default: begin
            DO[i] <= data[i];
            DO_K[i] <= (k[i] & ~en_se_replacement) | k_[i];
          end
        endcase

  always_ff @(posedge CLK)
    if (!RST_n || !EN)
      RDY <= 1'b0;
    else if (|ME && (multiframe_cnt == NUM_ILAS))
      RDY <= 1'b1;

endmodule