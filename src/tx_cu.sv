module tx_cu (
  input              CLK        ,
  input              RST_n      ,
  input              SYNC       ,
  input              LMFC_SYNCED,
  input        [3:0] LMFC_MS    ,
  input        [3:0] LMFC_ME    ,
  input        [3:0] ILA_ME     ,
  input        [3:0] ILA_RDY    ,
  output logic       LMFC_EN    ,
  output logic       ILA_EN     ,
  output logic       CHAR_EN
);

  typedef enum logic [4:0] {
    IDLE       = 5'b00001,
    LMFC_ALIGN = 5'b00010,
    CGS        = 5'b00100,
    ILA        = 5'b01000,
    DATA       = 5'b10000
  } sm_t;

  sm_t next_state;
  sm_t current_state;

  always_comb begin
    case (current_state)
      IDLE:
        next_state = LMFC_ALIGN;

      LMFC_ALIGN:
        if (LMFC_SYNCED)
          next_state = CGS;
        else
          next_state = LMFC_ALIGN;

      CGS:
        if (SYNC && |LMFC_MS)
          next_state = ILA;
        else
          next_state = CGS;

      ILA:
        if (ILA_RDY && |ILA_ME)
          next_state = DATA;
        else
          next_state = ILA;

      DATA:
        next_state = DATA;

      default:
        next_state = IDLE;
    endcase
  end

  always_ff @(negedge RST_n, posedge CLK)
    if (!RST_n)
      current_state <= IDLE;
    else
      current_state <= next_state;

  always_comb begin
    LMFC_EN = |current_state[4:1];
    ILA_EN  = |current_state[4:3];
    CHAR_EN = current_state == DATA;
  end

endmodule