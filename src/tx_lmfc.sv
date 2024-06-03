module tx_lmfc (
  input              CLK       ,
  input              RST_n     ,
  input              EN        ,
  input              SYSREF    ,
  input              LOAD_SETUP,
  input        [1:0] L         , // 1, 2, 4 lanes supported
  input        [7:0] F         , // 1, 2, 4, 8, 16 octets per frame supported
  input        [4:0] K         , // 4, 8, 12, 16, 20, 24, 28, 32 frames per multiframe supported
  output logic [3:0] MS        ,
  output logic [3:0] ME        ,
  output logic [3:0] FS        ,
  output logic [3:0] FE        ,
  output logic       SYNCED
);

  logic load_setup_d;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      load_setup_d <= 1'b0;
    else
      load_setup_d <= LOAD_SETUP;

  logic [5:0] frames;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n) begin
      frames <= 'b0;
    end else if (LOAD_SETUP && !load_setup_d) begin
      case (K)
        5'd3   : frames <= 8'd4 ;
        5'd7   : frames <= 8'd8 ;
        5'd11  : frames <= 8'd12;
        5'd15  : frames <= 8'd16;
        5'd19  : frames <= 8'd20;
        5'd23  : frames <= 8'd24;
        5'd27  : frames <= 8'd28;
        5'd31  : frames <= 8'd32;
        default: frames <= 8'd8 ;
      endcase
    end

  logic       additional_setup;
  logic [7:0] f               ;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      additional_setup <= 1'b0;
    else
      additional_setup <= LOAD_SETUP & ~load_setup_d;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      f <= 3'b010;
    else if (LOAD_SETUP && !load_setup_d)
      case (F)
        8'd1   : f <= 3'b001;
        8'd3   : f <= 3'b010;
        8'd7   : f <= 3'b100;
        8'd15  : f <= 3'b101;
        default: f <= 3'b000;
      endcase

  logic [9:0] lmfc_limit;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      lmfc_limit <= 10'd4;
    else if (additional_setup)
      case (f)
        3'b001 : lmfc_limit <= frames >> 1;
        3'b010 : lmfc_limit <= frames;
        3'b100 : lmfc_limit <= frames << 1;
        3'b101 : lmfc_limit <= frames << 2;
        default: lmfc_limit <= frames >> 2;
      endcase

  logic sysref_d          ;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n) begin
      sysref_d <= 1'b0;
      SYNCED <= 1'b0;
    end else if (EN) begin
      sysref_d <= SYSREF;

      if (SYSREF && !sysref_d)
        SYNCED <= 1'b1;
    end

  logic       lmfc_reset;
  logic [9:0] lmfc_cnt  ;

  always_comb
    if (!SYNCED && SYSREF && !sysref_d && EN)
      lmfc_reset = 1'b1;
    else
      lmfc_reset = 1'b0;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      lmfc_cnt <= 'b0;
    else if (EN) begin
      if (additional_setup || lmfc_reset || (lmfc_cnt == lmfc_limit - 1))
        lmfc_cnt <= 'b0;
      else
        lmfc_cnt <= lmfc_cnt + 1;
    end

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

  always_comb begin
    MS[0] = lmfc_cnt == 10'd0;
    MS[3:1] = 3'b000;

    ME[2:0] = 3'b000;
    ME[3] = lmfc_cnt == lmfc_limit - 1;
  end

endmodule