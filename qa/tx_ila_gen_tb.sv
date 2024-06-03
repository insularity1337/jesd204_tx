`timescale 1ns/1ps

module tx_ila_gen_tb ();

  logic            clk    = 1'b0           ;
  logic            rst_n  = 1'b0           ;
  logic            en     = 1'b0           ;
  logic [3:0]      fs     = 4'b0101        ;
  logic [3:0]      fe     = 4'b1010        ;
  logic [3:0]      ms     = 4'h0           ;
  logic [3:0]      me     = 4'h0           ;
  logic [3:0]      ms_out                  ;
  logic [3:0]      me_out                  ;
  logic [3:0][7:0] din    = 32'h5E_5E_5E_5E;
  logic [3:0][7:0] dout                    ;

  tx_ila_gen dut (
    .CLK       (clk   ),
    .RST_n     (rst_n ),
    .EN        (en    ),
    .FS        (fs    ),
    .FE        (fe    ),
    .MS        (ms    ),
    .ME        (me    ),
    .DI        (din   ),
    .LOAD_SETUP(      ),
    .ADJCNT    ('b0   ),
    .ADJDIR    ('b0   ),
    .BID       ('b0   ),
    .CF        ('b0   ),
    .CS        ('b0   ),
    .DID       ('b0   ),
    .F         ('b0   ),
    .HD        ('b0   ),
    .JESDV     ('b0   ), // b only
    .K         ('b0   ),
    .L         ('b0   ),
    .LID       ('b0   ),
    .M         ('b0   ),
    .N         ('b0   ),
    .N_        ('b0   ),
    .PHADJ     ('b0   ),
    .S         ('b0   ),
    .SCR       ('b0   ),
    .SUBCLASSV ('b0   ), // 1 only
    .RES1      ('b0   ),
    .RES2      ('b0   ),
    .CHKSUM    ('b0   ),
    .MS_OUT    (ms_out),
    .ME_OUT    (me_out),
    .DO        (dout  )
  );

  initial
    forever
      #5 clk = ~clk;

  initial
    #13 rst_n = ~rst_n;

  initial
    forever begin
      ms <= 4'h1;
      @(posedge clk);
      ms <= 4'h0;
      repeat(6)
        @(posedge clk);
      me <= 4'h8;
      @(posedge clk);
      me <= 4'h0;
    end

  initial begin


    #2us;
    $finish;
  end

  initial begin
    repeat(13)
      @(posedge clk);

    @(posedge |ms);
    en <= 1'b1;
  end

  initial begin
    $dumpfile("ila.vcd");
    $dumpvars(0, dut);
  end

endmodule