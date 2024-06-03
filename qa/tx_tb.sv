`timescale 1ns/1ps

module tx_tb ();

  logic            clk    = 1'b0;
  logic            rst_n  = 1'b1;
  logic            rdy          ;
  logic [3:0][7:0] din          ;
  logic [3:0][7:0] dout         ;
  logic            sync_n = 1'b0;
  logic            sysref = 1'b0;

  tx dut (
    .CLK      (clk   ),
    .RST_n    (rst_n ),
    .ADJCNT   ('b0   ),
    .ADJDIR   ('b0   ),
    .BID      ('b0   ),
    .CF       ('b0   ),
    .CS       ('b0   ),
    .DID      ('b0   ),
    .F        (3'b010),
    .HD       ('b0   ),
    .JESDV    ('b0   ),
    .K        (3'b001),
    .L        ('b0   ),
    .LID      ('b0   ),
    .M        ('b0   ),
    .N        ('b0   ),
    .N_       ('b0   ),
    .PHADJ    ('b0   ),
    .S        ('b0   ),
    .SCR      ('b0   ),
    .SUBCLASSV('b0   ),
    .RES1     ('b0   ),
    .RES2     ('b0   ),
    .CHKSUM   ('b0   ),
    .RDY      (rdy   ),
    .DI       (din   ),
    .DO       (dout  ),
    .SYNC_n   (sync_n),
    .SYSREF   (sysref)
  );

  initial
    forever
      #5 clk = ~clk;

  initial begin
    rst_n = ~rst_n;
    #13 rst_n = ~rst_n;
  end

  initial begin

    repeat($urandom_range(25, 50))
      @(negedge clk);

    sysref <= 1'b1;
    @(negedge clk);
    sysref <= 1'b0;

    repeat($urandom_range(10, 20))
      @(posedge clk);

    sync_n <= ~sync_n;

    #500;
    $finish;
  end

  initial begin
    for (int i = 0; i < 4; i++)
      din = {8'h00, 8'h00, 8'h00, 8'h00};

    @(posedge rdy);

    forever begin
      @(posedge clk);

      din = {8'hAA, 8'h00, 8'h00, 8'h00};
      @(posedge clk);
      din = {8'hAA, 8'h00, 8'h00, 8'h00};

    end
  end

  initial begin
    $dumpfile("tx.vcd");
    $dumpvars(0, dut);
  end

endmodule