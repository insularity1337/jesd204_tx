module tx_ila_gen (
  input                   CLK       ,
  input                   RST_n     ,
  input                   EN        ,
  input        [3:0]      FS        ,
  input        [3:0]      FE        ,
  input        [3:0]      MS        ,
  input        [3:0]      ME        ,
  input        [3:0][7:0] DI        ,
  // ILA frame #2 data
  input                   LOAD_SETUP,
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
  output logic [3:0][7:0] DO
);

  logic en;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      en <= 1'b0;
    else if (|ME)
      en <= EN;

  logic [3:0] multiframe_id;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      multiframe_id <= 4'b0000;
    else if (|ME)
      multiframe_id <= {multiframe_id[2:0], (EN & ~en)};

  logic en_se_replacement;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      en_se_replacement <= 1'b0;
    else
      en_se_replacement <= |multiframe_id;

  logic [3:0] conf_data;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      conf_data <= 'b0;
    else if (EN) begin
      conf_data <= {conf_data[2:0], (|ME & multiframe_id[0])};
    end else
      conf_data <= 'b0;

  logic [3:0][7:0] data;

  // Octet #0
  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      data[0] <= 'b0;
    else if (|multiframe_id)
      case (conf_data)
        4'b0001: data[0] <= 8'h00;
        4'b0010: data[0] <= {1'b0, ADJDIR, PHADJ, LID};
        4'b0100: data[0] <= M;
        4'b1000: data[0] <= {HD, 2'b00, CF};
        default: data[0] <= 8'h00;
      endcase
    else
      data[0] <= DI[0];

  // Octet #1
  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      data[1] <= 'b0;
    else if (|multiframe_id)
      case (conf_data)
        4'b0001: data[1] <= 8'b100_11100;
        4'b0010: data[1] <= {SCR, 2'b00, L};
        4'b0100: data[1] <= {CS, 1'b0, N};
        4'b1000: data[1] <= RES1;
        default: data[1] <= 8'h00;
      endcase
    else
      data[1] <= DI[1];

  // Octet #2
  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      data[2] <= 'b0;
    else if (|multiframe_id)
      case (conf_data)
        4'b0001: data[2] <= DID;
        4'b0010: data[2] <= F;
        4'b0100: data[2] <= {SUBCLASSV, N_};
        4'b1000: data[2] <= RES2;
        default: data[2] <= 8'h00;
      endcase
    else
      data[2] <= DI[2];

  // Octet #3
  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      data[3] <= 'b0;
    else if (|multiframe_id)
      case (conf_data)
        4'b0001: data[3] <= {ADJCNT, BID};
        4'b0010: data[3] <= {3'b000, K};
        4'b0100: data[3] <= {JESDV, S};
        4'b1000: data[3] <= CHKSUM;
        default: data[3] <= 8'h00;
      endcase
    else
      data[3] <= DI[3];

  logic [3:0] fs, fe;
  logic [3:0] me, ms;

  always_ff @(negedge RST_n, posedge CLK)
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

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      {FS_OUT, FE_OUT, MS_OUT, ME_OUT} <= 'b0;
    else
      {FS_OUT, FE_OUT, MS_OUT, ME_OUT} <= {fs, fe, ms, me};

  // Start and end of frame character replacement
  for (genvar i = 0; i < 4; i++)
    always_ff @(negedge RST_n, posedge CLK)
      if (!RST_n)
        DO[i] <= 'b0;
      else
        case ({en_se_replacement, me[i], ms[i]})
          3'b1_01: DO[i] <= 8'b000_11100; // /R/
          3'b1_10: DO[i] <= 8'b011_11100; // /A/
          default: DO[i] <= data[i];
        endcase

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      RDY <= 1'b0;
    else if (|ME && multiframe_id[3])
      RDY <= 1'b1;

endmodule