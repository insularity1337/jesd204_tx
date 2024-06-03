`timescale 1ns/1ps

module tx_lmfc_tb ();

  logic       clk        = 1'b0;
  logic       rst_n      = 1'b0;
  logic       en         = 1'b0;
  logic       load_setup = 1'b0;
  logic       sysref     = 1'b0;
  logic [1:0] l                ;
  logic [2:0] f                ;
  logic [4:0] k                ;
  logic [3:0] ms               ;
  logic [3:0] me               ;
  logic [3:0] fs               ;
  logic [3:0] fe               ;

  tx_lmfc dut (
    .CLK       (clk       ),
    .RST_n     (rst_n     ),
    .EN        (en        ),
    .LOAD_SETUP(load_setup),
    .SYSREF    (sysref    ),
    .L         (l         ), // 1, 2, 4 lanes supported
    .F         (f         ), // 1, 2, 4, 8, 16 octets per frame supported
    .K         (k         ), // 4, 8, 12, 16, 20, 24, 28, 32 frames per multiframe supported
    .MS        (ms        ),
    .ME        (me        ),
    .FS        (fs        ),
    .FE        (fe        ),
    .SYNCED    (          )
  );

  initial
    forever
      #5 clk = ~clk;

  initial
    #13 rst_n = ~rst_n;

  initial begin
    repeat(10)
      @(posedge clk);

    f <= 3'b010;
    k <= 3'b001;
    load_setup <= 1'b1;
    @(posedge clk);
    f <= 3'b000;
    k <= 3'b000;
    load_setup <= 1'b0;

    repeat($urandom_range(25, 50))
      @(negedge clk);

    sysref <= 1'b1;
    @(negedge clk);
    sysref <= 1'b0;

    #2us;
    $finish;
  end

  initial begin
    repeat($urandom_range(10, 20))
      @(posedge clk);

    en <= 1'b1;
  end

  initial begin
    $dumpfile("lmfc.vcd");
    $dumpvars(0, dut);
  end

endmodule