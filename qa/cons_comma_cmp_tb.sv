`timescale 1ns/1ps

module cons_comma_cmp_tb ();

  logic [          1:0]      k     ;
  logic [          1:0][7:0] din   ;
  logic                      consec;
  logic [$clog2(2)-1:0]      dout  ;

  cons_comma_cmp #(2,8'b00111101) dut (
    .K     (k     ),
    .DI    (din   ),
    .CONSEC(consec),
    .DO    (dout  )
  );

  initial begin
    #10;
    k = 2'b01;
    din[0] = 8'b00111101;
    din[1] = $urandom_range(0, 255);
    #10;
    k = 2'b10;
    din[1] = 8'b00111101;
    din[0] = $urandom_range(0, 255);
    #10;
    k = 2'b11;
    din[0] = 8'b00111101;
    din[1] = 8'b00111101;
    #10;
    k = 2'b00;
    din[0] = $urandom_range(0, 255);
    din[1] = $urandom_range(0, 255);
    #10;
  end

  initial begin
    $dumpfile("cmp.vcd");
    $dumpvars(0, dut);
  end

endmodule