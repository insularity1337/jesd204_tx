module tx_lmfc (
  input              CLK       ,
  input              RST_n     ,
  input        [2:0] SUBCLASSV ,
  input              EN        ,
  input              SYSREF    ,
  input        [1:0] L         ,
  input        [7:0] F         , // 1, 2, 4, 8, 16 octets per frame supported
  input        [4:0] K         , // 4, 8, 12, 16, 20, 24, 28, 32 frames per multiframe supported
  output logic [3:0] MS        ,
  output logic [3:0] ME        ,
  output logic [3:0] FS        ,
  output logic [3:0] FE        ,
  output logic       SYNCED
);

  logic [5:0] frames    ;
  logic [7:0] f         ;
  logic [9:0] lmfc_limit;

  logic       sysref_d  ;
  logic       lmfc_reset;
  logic [9:0] lmfc_cnt  ;



  /*  Supported frame and multiframe length
   */
  always_comb begin
    frames = K + 1;

    case(F)
      8'd1   : f = 3'b001;
      8'd3   : f = 3'b010;
      8'd7   : f = 3'b100;
      8'd15  : f = 3'b101;
      default: f = 3'b000;
    endcase

    case (f)
      3'b001 : lmfc_limit = frames >> 1;
      3'b010 : lmfc_limit = frames;
      3'b100 : lmfc_limit = frames << 1;
      3'b101 : lmfc_limit = frames << 2;
      default: lmfc_limit = frames >> 2;
    endcase
  end

  /*  *Subclass 1 only* SYSREF based LMFC alignment
   */
  always_ff @(posedge CLK)
    if (!RST_n) begin
      sysref_d <= 1'b0;
      SYNCED <= 1'b0;
    end else if (EN) begin
      sysref_d <= SYSREF;

      if (SYSREF && !sysref_d)
        SYNCED <= 1'b1;
    end else begin
      sysref_d <= 1'b0;
      SYNCED <= 1'b0;
    end

  /*  *Subclass 1 only* first SYSREF active edge LMFC counter reset
   */
  always_comb
    if (!SYNCED && SYSREF && !sysref_d && EN && (SUBCLASSV != 3'b000))
      lmfc_reset = 1'b1;
    else
      lmfc_reset = 1'b0;

  /*  LMFC counter
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      lmfc_cnt <= 10'd0;
    else if (EN) begin
      if (lmfc_reset || (lmfc_cnt == lmfc_limit - 1))
        lmfc_cnt <= 'b0;
      else
        lmfc_cnt <= lmfc_cnt + 1;
    end else
      lmfc_cnt <= 10'd0;

  /*  Frame start & end flags generation
   */
  always_comb begin
    if ((!f[2]) || ((f == 3'b100) && (!lmfc_cnt[0])) || ((f == 3'b101) && (lmfc_cnt[1:0] == 2'b00)))
      FS[0] = 1'b1;
    else
      FS[0] = 1'b0;

    if (f < 3'b010)
      FS[2] = 1'b1;
    else
      FS[2] = 1'b0;

    if (f == 3'b000) begin
      FS[1] = 1'b1;
      FS[3] = 1'b1;
    end else begin
      FS[1] = 1'b0;
      FS[3] = 1'b0;
    end

    if ((!f[2]) || ((f == 3'b100) && lmfc_cnt[0]) || ((f == 3'b101) && (lmfc_cnt[1:0] == 2'b11)))
      FE[3] = 1'b1;
    else
      FE[3] = 1'b0;

    if (f < 3'b010)
      FE[1] = 1'b1;
    else
      FE[1] = 1'b0;

    if (f == 3'b000) begin
      FE[0] = 1'b1;
      FE[2] = 1'b1;
    end else begin
      FE[0] = 1'b0;
      FE[2] = 1'b0;
    end
  end

  /*  Multiframe start & end flags generation
   */
  always_comb begin
    MS[0] = lmfc_cnt == 10'd0;
    MS[3:1] = 3'b000;

    ME[2:0] = 3'b000;
    ME[3] = lmfc_cnt == lmfc_limit - 1;
  end

endmodule