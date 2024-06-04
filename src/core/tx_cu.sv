module tx_cu #(parameter LANES = 1) (
  input                    CLK        ,
  input                    RST_n      ,
  input        [LANES-1:0] LANE_EN    ,
  input        [      7:0] ILA_DELAY  ,
  input        [      2:0] SUBCLASSV  ,
  input                    SYNC       ,
  input                    LMFC_SYNCED,
  input        [      3:0] LMFC_MS    ,
  input        [      3:0] LMFC_ME    ,
  input        [      3:0] ILA_ME     ,
  input        [      3:0] ILA_RDY    ,
  output logic             LMFC_EN    ,
  output logic [LANES-1:0] ILA_EN     ,
  output logic [LANES-1:0] CHAR_EN
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

  logic ila_sm;
  logic char_sm;

  logic [7:0] mf_cnt;

  always_comb begin
    case (current_state)
      IDLE:
        if (SUBCLASSV == 3'b000)
          next_state = CGS;
        else
          next_state = LMFC_ALIGN;

      LMFC_ALIGN:
        if (LMFC_SYNCED)
          next_state = CGS;
        else
          next_state = LMFC_ALIGN;

      CGS:
        if (SYNC && (mf_cnt == ILA_DELAY))
          next_state = ILA;
        else
          next_state = CGS;

      ILA:
        if (|ILA_RDY && |ILA_ME)
          next_state = DATA;
        else
          next_state = ILA;

      DATA:
        if (!SYNC)
          next_state = IDLE;
        else
          next_state = DATA;

      default:
        next_state = IDLE;
    endcase
  end

  always_ff @(posedge CLK)
    if (!RST_n)
      mf_cnt <= 8'h00;
    else
      case (current_state)
        CGS: begin
          if (SYNC)
            if (|LMFC_ME && (mf_cnt < ILA_DELAY))
              mf_cnt <= mf_cnt + 1;
        end

        default:
          mf_cnt <= 8'h00;
    endcase

  always_ff @(posedge CLK)
    if (!RST_n)
      current_state <= IDLE;
    else
      current_state <= next_state;

  always_comb begin
    LMFC_EN = |current_state[4:1];

    ila_sm = |current_state[4:3];
    char_sm = current_state == DATA;
  end

  for (genvar i = 0; i < LANES; i++)
    always_comb begin
      if (LANE_EN[i] && ila_sm)
        ILA_EN[i] = 1'b1;
      else
        ILA_EN[i] = 1'b0;

      if (LANE_EN[i] && char_sm)
        CHAR_EN[i] = 1'b1;
      else
        CHAR_EN[i] = 1'b0;
    end

endmodule