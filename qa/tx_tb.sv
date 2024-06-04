`timescale 1ns/1ps

module tx_tb ();

    localparam LANES = 4;

  logic        pclk    = 1'b0;
  logic        presetn = 1'b0;
  logic [31:0] paddr         ;
  logic [ 2:0] pprot         ;
  logic        pnse          ;
  logic        psel          ;
  logic        penable       ;
  logic        pwrite        ;
  logic [31:0] pwdata        ;
  logic [ 3:0] pstrb         ;
  logic        pready        ;
  logic [31:0] prdata        ;
  logic        pslverr       ;
  logic        pwakeup       ;
  logic [ 7:0] pauser        ;
  logic [ 7:0] pwuser        ;
  logic [ 7:0] pruser        ;
  logic [ 7:0] pbuser        ;

  logic        aclk    = 1'b0 ;
  logic        aresetn = 1'b0 ;
  logic [11:0] awaddr  = 12'd0;
  logic        awvalid = 1'b0 ;
  logic        awready        ;
  logic [31:0] wdata   = 32'd0;
  logic [ 3:0] wstrb   = 4'd0 ;
  logic        wvalid  = 1'b0 ;
  logic        wready         ;
  logic [ 1:0] bresp          ;
  logic        bvalid         ;
  logic        bready  = 1'b1 ;
  logic [11:0] araddr  = 12'd0;
  logic        arvalid = 1'b0 ;
  logic        arready        ;
  logic [31:0] rdata          ;
  logic [ 1:0] rresp          ;
  logic        rvalid         ;
  logic        rready  = 1'b1 ;

  logic             sync_n          = 1'b1;
  logic             sysref          = 1'b0;
  logic             rdy                   ;
  logic             qpll_refclk     = 1'b0;
  logic             drpclk          = 1'b0;
  logic             qpll_clk_out          ;
  logic             qpll_refclk_out       ;
  logic             qpll_lock_out         ;
  logic [LANES-1:0] tx_n                  ;
  logic [LANES-1:0] tx_p                  ;
  logic             sys_reset       = 1'b0;
  logic             rx_rst          = 1'b0;

  logic [LANES-1:0][3:0][7:0] di = '{
    {8'h0F, 8'h0E, 8'h0D, 8'h0C},
    {8'h0B, 8'h0A, 8'h09, 8'h08},
    {8'h07, 8'h06, 8'h05, 8'h04},
    {8'h03, 8'h02, 8'h01, 8'h00}
  };

  logic                       rx_aresetn;
  logic                       rx_tvalid ;
  logic [LANES-1:0][3:0][7:0] rx_tdata  ;

  task apb_write(input logic [31:0] addr, logic [31:0] data);
    @(posedge pclk);
    psel    <= 1'b1;
    penable <= 1'b1;
    pwrite  <= 1'b1;
    paddr   <= addr;
    pwdata  <= data;
    pstrb   <= 4'hF;
    @(posedge pclk);
    psel    <= 1'b0;
    penable <= 1'b0;
    pwrite  <= 1'b0;
    paddr   <= {32{1'b0}};
    pwdata  <= {32{1'b0}};
    pstrb   <= 4'h0;
  endtask

  task axi_write(input logic [31:0] addr, logic [31:0] data);
    @(posedge aclk);
    awaddr  <= addr;
    awvalid <= 1;
    wdata   <= data;
    wvalid  <= 1;
    bready  <= 0;

    @(negedge aclk);
      while (awready == 1'b0)
        @(negedge aclk);
    @(posedge aclk);

    awaddr  <= {32{1'b0}};
    awvalid <= {32{1'b0}};

    @(negedge aclk);
    while (wready == 1'b0)
      @(negedge aclk);
    @(posedge aclk);

    wdata  <= 0;
    wvalid <= 0;

    @(negedge aclk);
    while (bvalid == 1'b0)
      @(negedge aclk);

    @(posedge aclk);
    if (bresp != 0)
      $display("AXI BRESP not equal 0");

    bready <= 1;
    @(posedge aclk);
    bready <= 0;
  endtask

  initial
    forever
      #10 pclk = ~pclk;

  initial
    #137ns presetn = ~presetn;

  initial
    forever
      #5 drpclk = ~drpclk;

  initial
    forever
      #2.5 qpll_refclk = ~qpll_refclk;

  initial begin : data_gen
    @(posedge rdy);

    forever begin
      @(posedge qpll_refclk);
      for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            di[i][j] += 1;
    end
  end

  jesd204_tx_env #(4) dut (
    .PCLK       (pclk       ),
    .PRESETn    (presetn    ),
    .PADDR      (paddr      ),
    .PPROT      (pprot      ),
    .PNSE       (pnse       ),
    .PSEL       (psel       ),
    .PENABLE    (penable    ),
    .PWRITE     (pwrite     ),
    .PWDATA     (pwdata     ),
    .PSTRB      (pstrb      ),
    .PREADY     (pready     ),
    .PRDATA     (prdata     ),
    .PSLVERR    (pslverr    ),
    .PWAKEUP    (pwakeup    ),
    .PAUSER     (pauser     ),
    .PWUSER     (pwuser     ),
    .PRUSER     (pruser     ),
    .PBUSER     (pbuser     ),
    .SYNC_n     (sync_n     ),
    .SYSREF     (sysref     ),
    .CLK        (qpll_refclk),
    .RDY        (rdy        ),
    .DI         (di         ),
    .QPLL_REFCLK(qpll_refclk),
    .DRPCLK     (drpclk     ),
    .TX_N       (tx_n       ),
    .TX_P       (tx_p       )
  );

  initial
    forever
      #10 aclk = ~aclk;

  initial
    #87ns aresetn = ~aresetn;

  initial begin
    #1us;
    sys_reset = 1'b1;
    #1us;
    sys_reset = 1'b0;
  end

  initial begin
    #100ns;
    @(posedge qpll_refclk);
    rx_rst <= 1'b1;
    #100ns;
    @(posedge qpll_refclk);
    rx_rst <= 1'b0;
  end

  initial begin
    #30us;
    forever begin
      @(posedge qpll_refclk);
      sysref <= 1'b1;
      @(posedge qpll_refclk);
      sysref <= 1'b0;
      repeat(1022)
        @(posedge qpll_refclk);
    end
  end

  logic [31:0] cfg;

  always_comb begin
    cfg[31:24] = 8'd3; // Ila multiframes
    cfg[21:20] = 2'b00; // Reserved; must be zero
    cfg[19]    = 1'b1; // Enable link error counters
    cfg[18]    = 1'b1; // Error reporting via sync
    cfg[17]    = 1'b1; // ILA required
    cfg[16]    = 1'b0; // Scrambling
    cfg[15:13] = 3'd0; // ?
    cfg[12:8]  = 5'd31; // K
    cfg[7:0]   = 8'd1; // F
  end

  initial begin
    #100ns;
    axi_write(32'h20, 32'h1);
    #1us;
    axi_write(32'h20, 32'h0);
    #1us;
    #100ns;
    axi_write(32'h64, 32'h6);
    #100ns;
    axi_write(32'h3C, cfg);
  end

  rx_env rx (
    .ACLK       (aclk       ),
    .ARESETN    (aresetn    ),
    .AWADDR     (awaddr     ),
    .AWVALID    (awvalid    ),
    .AWREADY    (awready    ),
    .WDATA      (wdata      ),
    .WSTRB      (wstrb      ),
    .WVALID     (wvalid     ),
    .WREADY     (wready     ),
    .BRESP      (bresp      ),
    .BVALID     (bvalid     ),
    .BREADY     (bready     ),
    .ARADDR     (araddr     ),
    .ARVALID    (arvalid    ),
    .ARREADY    (arready    ),
    .RDATA      (rdata      ),
    .RRESP      (rresp      ),
    .RVALID     (rvalid     ),
    .RREADY     (rready     ),
    .QPLL_REFCLK(qpll_refclk),
    .DRPCLK     (drpclk     ),
    .SYS_RESET  (sys_reset  ),
    .CLK        (           ),
    .RST        (rx_rst     ),
    .SYSREF     (sysref     ),
    .SYNC_n     (sync_n     ),
    .RX_ARESETN (rx_aresetn ),
    .RX_TVALID  (rx_tvalid  ),
    .RX_TDATA   (rx_tdata   ),
    .RX_N       (tx_n       ),
    .RX_P       (tx_p       )
  );

  initial begin
    #1us;
    apb_write(32'h38, 32'h1);
    #1us;
    apb_write(32'h38, 32'h0);
    #10us;
                    // F      DID   CS    CF    BID   ADJDIR  ADJCNT
    apb_write(32'h00, {8'd1, 8'h55, 2'd2, 5'd1, 4'hA, 1'b0, 4'h0});
                    //         N      M    L     K     JESDV   HD
    apb_write(32'h04, {5'd0, 5'd13, 8'd0, 5'd0, 5'd31, 3'b001, 1'b0});
                    // RES2   RES1  SUBV    SCR     S   PHADJ   N_
    apb_write(32'h08, {8'hA5, 8'h5A, 3'b001, 1'b0, 5'd0, 1'b0, 5'd15});

    // Lane IDs
    apb_write(32'h0c, 32'h0);
    apb_write(32'h10, 32'h1);
    apb_write(32'h14, 32'h2);
    apb_write(32'h18, 32'h3);

    // CHKSUMs
    apb_write(32'h1c, 32'h9F);
    apb_write(32'h20, 32'h0);
    apb_write(32'h24, 32'h0);
    apb_write(32'h28, 32'h0);

    apb_write(32'h2c, {15'd0, 1'b1, 8'd0, 8'd3});
    apb_write(32'h30, 32'h0000_000F);
    apb_write(32'h34, 32'd1);

    #1.5us;
    apb_write(32'h34, 32'h1);
  end

  byte foo = 0;

  initial begin : pseudo_scoreboard
    @(posedge aresetn);
    @(posedge rx_aresetn);
    @(posedge rx_tvalid)
    for (int i = 0; i < 1000; i++) begin
      @(negedge qpll_refclk);

      for (int j = 0; j < 4; j++)
        for (int k = 0; k < 4; k++)
          if (rx_tdata[j][k] != byte'((foo + j*4 + k))) begin
            $error("Received wrong data: received data: %d\tblueprint: %d", rx_tdata[j][k], byte'((foo + j*4 + k)));
            $finish;
          end

      foo += 1;
    end
    $display("Everything is fine");
    $finish;
  end

endmodule