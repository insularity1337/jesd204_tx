`timescale 1ns/1ns

module comma_detect_tb ();

  logic        clk   = 1'b0 ;
  logic        arstn = 1'b0 ;
  logic [19:0] din   = 20'd0;
  logic [19:0] dout         ;
  logic        k            ;
  logic        req   = 1'b0 ;
  logic        dvo          ;
  logic        START        ;

  comma_detect dut (
    .CLK  (clk  ),
    .ARSTN(arstn),
    .REQ  (req  ),
    .DI   (din  ),
    .K    (k    ),
    .DVO  (dvo  ),
    .DO   (dout )
  );

  initial
    #13 arstn = ~arstn;

  initial
    forever
      #5 clk = ~clk;

  initial begin
    // $display("%b", ~dut.comma[9 -: 6]);

    // @(posedge arstn);

    repeat($urandom_range(10, 20)) begin
      @(posedge clk);
      din <= $urandom_range(0, 2**20-1);
    end

    // $display("Start of /K/ symbols; time: %t", $time());

    @(posedge clk);
    din[9:0] <= dut.comma;

    repeat($urandom_range(10, 20)) begin
      @(posedge clk);
      din <= $urandom_range(0, 2**20-1);
    end

    @(posedge clk)
    din <= 20'd0;

    // forever begin
    //   @(posedge clk);
    //   din[19:10] <= 10'b1100000101;
    //   din[ 9: 0] <= 10'b0011111010;
    // end
  end

  initial begin
    repeat(10)
      @(posedge clk);

    req <= 1'b1;
    @(posedge clk);
    req <= 1'b0;
  end

  initial begin
    #1000;
    $finish;
  end

  initial begin
    $dumpfile("comma.vcd");
    $dumpvars(0, dut);
  end

endmodule