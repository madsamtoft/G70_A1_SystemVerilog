module fsm (
  input  logic       clk,
  input  logic       reset,
  input  logic       req,
  input  logic       N, Z,
  output logic       ack,
  output logic       LDA, LDB,
  output logic       ABorALU,
  output logic [1:0] fn
);
  typedef enum logic [2:0] {
    op_a_await,
    op_a_release,
    op_b_await,
    calculate,
    subtract_b,
    result_release
  } state_t;

  state_t state, next_state;

  // Combinational FSM
  always_comb begin
    // Default values
    next_state = state;

    ack     = 1'b0;
    LDA     = 1'b0;
    LDB     = 1'b0;
    ABorALU = 1'b0;  // AB is selected by default
    fn      = 2'b00; // A - B is selected by default

    // State transition logic
    case (state)
      op_a_await: begin
        if (req) begin
          LDA        = 1'b1;
          next_state = op_a_release;
        end
      end

      op_a_release: begin
        ack = 1'b1;
        if (!req) begin
          next_state = op_b_await;
        end
      end

      op_b_await: begin
        if (req) begin
          LDB        = 1'b1;
          next_state = calculate;
        end
      end

      calculate: begin
        ABorALU = 1'b1;  // ALU is selected
        fn      = 2'b00; // A - B is selected 
        if (Z) begin
          // A == B -> GCD found
          next_state = result_release;
        end else if (N) begin
          // A - B < 0 -> B > A
          next_state = subtract_b;
        end else begin
          // A - B > 0 -> A > B
          LDA = 1'b1; // Load result into A
        end
      end

      subtract_b: begin
        ABorALU = 1'b1;  // ALU is selected
        fn      = 2'b01; // B - A is selected
        LDB     = 1'b1;  // Load result into B

        next_state = calculate;
      end

      result_release: begin
        ack = 1'b1;
        if (!req) begin
          next_state = op_a_await;
        end
      end

      default: next_state = op_a_await;
    endcase
  end

  // State Register
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= op_a_await;
    end else begin
      state <= next_state;
    end
  end

endmodule