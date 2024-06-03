module tx_char_replace (
  input                   CLK  ,
  input                   RST_n,
  input                   EN   ,
  input        [7:0]      F    ,
  input        [3:0]      FE   ,
  input        [3:0]      ME   ,
  input        [3:0][7:0] DI   ,
  output logic [3:0][7:0] DO
);

  logic [1:0][3:0] fe;
  logic [1:0][3:0] me;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n) begin
      fe <= 'b0;
      me <= 'b0;
    end else begin
      fe <= {fe[0], FE};
      me <= {me[0], ME};
    end

  logic [1:0][3:0][7:0] prev_sample;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      prev_sample <= 'b0;
    else
      prev_sample <= {prev_sample[0], DI};

  logic [3:0][7:0] last_fe;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      last_fe <= 'b0;
    else if (|FE && EN)
      last_fe <= DI;

  logic en1;
  logic en2;
  logic en4;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n) begin
      en1 <= 1'b0;
      en2 <= 1'b0;
      en4 <= 1'b0;
    end else if (EN) begin
      if (|FE && (F == 8'd0/*3'b000*/))
        en1 <= 1'b1;

      if (|FE && (F == 8'd1/*3'b001*/))
        en2 <= 1'b1;

      if (|FE && (F > 8'd2/*3'b010*/))
        en4 <= 1'b1;
    end else begin
      en1 <= 1'b0;
      en2 <= 1'b0;
      en4 <= 1'b0;
    end

  logic [3:0] f1_last_eq;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      f1_last_eq <= 'b0;
    else if (en1) begin
      f1_last_eq[0] <= DI[0] == /*prev_sample[0]*/last_fe[3];
      f1_last_eq[1] <= DI[1] == DI[0];
      f1_last_eq[2] <= DI[2] == DI[1];
      f1_last_eq[3] <= DI[3] == DI[2];
    end

  logic [3:0] foo1           ;
  logic [3:0] f1_was_replaced;

  always_comb begin
    if (f1_last_eq[0] && !f1_was_replaced[3] && en1)
      foo1[0] = 1'b1;
    else
      foo1[0] = 1'b0;

    if (f1_last_eq[1] && !foo1[0] && en1)
      foo1[1] = 1'b1;
    else
      foo1[1] = 1'b0;

    if (f1_last_eq[2] && !foo1[1] && en1)
      foo1[2] = 1'b1;
    else
      foo1[2] = 1'b0;

    if (f1_last_eq[3] && (!foo1[2] || me[0][3]) && en1)
      foo1[3] = 1'b1;
    else
      foo1[3] = 1'b0;
  end

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      f1_was_replaced <= 'b0;
    else
      f1_was_replaced <= foo1;

  logic [3:0] f2_last_eq;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      f2_last_eq <= 'b0;
    else if (en2) begin
      f2_last_eq[0] <= 1'b0;
      f2_last_eq[1] <= DI[1] == /*prev_sample[0]*/last_fe[3];
      f2_last_eq[2] <= 1'b0;
      f2_last_eq[3] <= DI[3] == DI[1];
    end

  logic [3:0] foo2           ;
  logic [3:0] f2_was_replaced;

  always_comb begin
    foo2[0] = 1'b0;

    if (f2_last_eq[1] && !f2_was_replaced[3] && en2)
      foo2[1] = 1'b1;
    else
      foo2[1] = 1'b0;

    foo2[2] = 1'b0;

    if (f2_last_eq[3] && (!foo2[1] || me[0][3]) && en2)
      foo2[3] = 1'b1;
    else
      foo2[3] = 1'b0;
  end

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      f2_was_replaced <= 'b0;
    else
      f2_was_replaced <= foo2;

  logic [3:0] f4_last_eq;

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      f4_last_eq <= 'b0;
    else if (en4) begin
      f4_last_eq[2:0] <= 3'b000;
      f4_last_eq[3]   <= DI[3] == /*prev_sample*/last_fe[3];
    end

  logic [3:0] foo4           ;
  logic [3:0] f4_was_replaced;

  always_comb begin
    foo4[2:0] = 'b0;

    if (f4_last_eq[3] && (!f4_was_replaced[3] || me[0][3]) && en4)
      foo4[3] = 1'b1;
    else
      foo4[3] = 1'b0;
  end

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      f4_was_replaced <= 'b0;
    else
      f4_was_replaced <= foo4;

  logic [3:0] replace;

  for (genvar i = 0; i < 4; i++) begin
    always_comb
      replace[i] = f1_was_replaced[i] | f2_was_replaced[i] | f4_was_replaced[i];

    always_ff @(negedge RST_n, posedge CLK)
      if (!RST_n)
        DO[i] <= 'b0;
      else
        case ({me[1][i], replace[i]})
          2'b01  : DO[i] <= 8'b111_11100; // K28.7
          2'b11  : DO[i] <= 8'b011_11100; // K28.3
          default: DO[i] <= prev_sample[1][i];
        endcase
  end

endmodule