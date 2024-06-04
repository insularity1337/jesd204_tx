module tx_char_replace (
  input                   CLK  ,
  input                   RST_n,
  input                   EN   ,
  input        [7:0]      F    ,
  input        [3:0]      FE   ,
  input        [3:0]      ME   ,
  input        [3:0]      DI_K ,
  input        [3:0][7:0] DI   ,
  output logic [3:0]      DO_K ,
  output logic [3:0][7:0] DO
);

  logic [1:0][3:0]      fe         ;
  logic [1:0][3:0]      me         ;
  logic [1:0][3:0][7:0] prev_sample;
  logic [1:0][3:0]      prev_k     ;
  logic [3:0][7:0]      last_fe    ;

  logic en1;
  logic en2;
  logic en4;

  logic [3:0] f1_last_eq     ;
  logic [3:0] foo1           ;
  logic [3:0] f1_was_replaced;
  logic [3:0] f2_last_eq     ;
  logic [3:0] foo2           ;
  logic [3:0] f2_was_replaced;
  logic [3:0] f4_last_eq     ;
  logic [3:0] foo4           ;
  logic [3:0] f4_was_replaced;
  logic [3:0] replace_f4     ;
  logic [3:0] replace        ;



  /*  Delay for external multi- and frame end
   */
  always_ff @(posedge CLK)
    if (!RST_n) begin
      fe <= 'b0;
      me <= 'b0;
    end else begin
      fe <= {fe[0], FE};
      me <= {me[0], ME};
    end

  /*  Data stream delay
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      prev_sample <= 'b0;
    else
      prev_sample <= {prev_sample[0], DI};

  /*  Externla comma octet flags delay
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      prev_k <= {2{4'h0}};
    else
      prev_k <= {prev_k[0], DI_K};

  always_ff @(posedge CLK)
    if (!RST_n)
      last_fe <= 'b0;
    else if (|FE && EN)
      last_fe <= DI;

  /*  Replacement mode (frame is a multiple of 1, 2 or 4)
   */
  always_ff @(posedge CLK)
    if (!RST_n) begin
      en1 <= 1'b0;
      en2 <= 1'b0;
      en4 <= 1'b0;
    end else if (EN) begin
      if (|FE && (F == 8'd0))
        en1 <= 1'b1;

      if (|FE && (F == 8'd1))
        en2 <= 1'b1;

      if (|FE && (F > 8'd2))
        en4 <= 1'b1;
    end else begin
      en1 <= 1'b0;
      en2 <= 1'b0;
      en4 <= 1'b0;
    end

  /*  Equality of frame end octets flag (F=1)
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      f1_last_eq <= 'b0;
    else if (EN && (F == 8'd0)) begin
      f1_last_eq[0] <= (DI[0] == last_fe[3]) && en1;
      f1_last_eq[1] <= DI[1] == DI[0];
      f1_last_eq[2] <= DI[2] == DI[1];
      f1_last_eq[3] <= DI[3] == DI[2];
    end

  /*  Valid replacement indication (F=1)
   */
  always_comb begin
    if (f1_last_eq[0] && !f1_was_replaced[3])
      foo1[0] = 1'b1;
    else
      foo1[0] = 1'b0;

    if (f1_last_eq[1] && !foo1[0])
      foo1[1] = 1'b1;
    else
      foo1[1] = 1'b0;

    if (f1_last_eq[2] && !foo1[1])
      foo1[2] = 1'b1;
    else
      foo1[2] = 1'b0;

    if (f1_last_eq[3] && (!foo1[2] || me[0][3]))
      foo1[3] = 1'b1;
    else
      foo1[3] = 1'b0;
  end

  always_ff @(posedge CLK)
    if (!RST_n)
      f1_was_replaced <= 'b0;
    else
      f1_was_replaced <= foo1;

  /*  Equality of frame end octets flag (F=2)
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      f2_last_eq <= 4'h0;
    else if (EN && (F == 8'd1)) begin
      f2_last_eq[0] <= 1'b0;
      f2_last_eq[1] <= (DI[1] == last_fe[3]) && en2;
      f2_last_eq[2] <= 1'b0;
      f2_last_eq[3] <= DI[3] == DI[1];
    end

  /*  Valid replacement indication (F=2)
   */
  always_comb begin
    foo2[0] = 1'b0;

    if (f2_last_eq[1] && !f2_was_replaced[3])
      foo2[1] = 1'b1;
    else
      foo2[1] = 1'b0;

    foo2[2] = 1'b0;

    if (f2_last_eq[3] && (!foo2[1] || me[0][3]))
      foo2[3] = 1'b1;
    else
      foo2[3] = 1'b0;
  end

  always_ff @(posedge CLK)
    if (!RST_n)
      f2_was_replaced <= 'b0;
    else
      f2_was_replaced <= foo2;

  /*  Equality of frame end octets flag (F=4)
   */
  always_ff @(posedge CLK)
    if (!RST_n)
      f4_last_eq <= 'b0;
    else if (en4) begin
      f4_last_eq[2:0] <= 3'b000;

      f4_last_eq[3] <= DI[3] == last_fe[3] && FE[3];
    end

  /*  Valid replacement indication (F=4)
   */
  always_comb begin
    foo4[2:0] = 'b0;

    if (f4_last_eq[3] && (!f4_was_replaced[3] || me[0][3]))
      foo4[3] = 1'b1;
    else
      foo4[3] = 1'b0;
  end

  always_ff @(posedge CLK)
    if (!RST_n)
      f4_was_replaced <= 'b0;
    else if (fe[0][3])
      f4_was_replaced <= foo4;

  always_ff @(posedge CLK)
    if (!RST_n)
      replace_f4 <= 'b0;
    else
      replace_f4 <= foo4;


  for (genvar i = 0; i < 4; i++) begin
    always_comb
      replace[i] = f1_was_replaced[i] | f2_was_replaced[i] | replace_f4[i];

    always_ff @(posedge CLK)
      if (!RST_n) begin
        DO[i] <= 8'h00;
        DO_K[i] <= 1'b0;
      end else
        case ({me[1][i], replace[i]})

          2'b01: begin
            DO[i] <= 8'b111_11100; // K28.7
            DO_K[i] <= 1'b1;
          end

          2'b11: begin
            DO[i] <= 8'b011_11100; // K28.3
            DO_K[i] <= 1'b1;
          end

          default: begin
            DO[i] <= prev_sample[1][i];
            DO_K[i] <= prev_k[1][i];
          end
        endcase
  end

endmodule