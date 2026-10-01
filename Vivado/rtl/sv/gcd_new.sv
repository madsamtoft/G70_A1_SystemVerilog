// -----------------------------------------------------------------------------
//
//  Title      :  System Verilog FSMD implementation template for GCD
//             :
//  Developers :  Otto Westy Rasmussen
//             :
//  Purpose    :  This is a template for the FSMD (finite state machine with datapath) 
//             :  implementation of the GCD circuit
//             :
//  Revision   :  02203 fall 2025 v.1.0
//
// -----------------------------------------------------------------------------


module gcd (
    input  logic          clk,    // The clock signal.
    input  logic          reset,  // Reset the module.
    input  logic          req,    // Start computation.
    input  logic [15 : 0] AB,     // The two operands. One at a time.
    output logic          ack,    // Input received / Computation is complete.
    output logic [15 : 0] C       // The result.
);

  typedef enum logic [1 : 0] { 
    OP_A_AWAIT,
    OP_A_RELEASE,
    OP_B_AWAIT,
    CALCULATE,
    RESULT_RELEASE
  } state_t; 

  typedef enum logic [1:0] {
    A_MINUS_B,
    B_MINUS_A,
    PASS_A,
    PASS_B
} fn_t;

  state_t state, next_state;

  shortint unsigned reg_a, next_reg_a, reg_b, next_reg_b;

  logic [15:0] alu_lhs, alu_rhs;
  logic [15:0] Y;
  logic LDA, LDB;
  logic N, Z, ABorALU;
  fn_t FN;
    
  // Combinatorial logic
  always_comb begin

    // ALU Functionality
    case (FN)
      A_MINUS_B: begin
        alu_lhs = reg_a;
        alu_rhs = reg_b;
      end

      B_MINUS_A: begin
        alu_lhs = reg_b;
        alu_rhs = reg_a;
      end

      default: begin
        alu_lhs = reg_a;
        alu_rhs = reg_b;
      end
    endcase

    alu_sub = alu_lhs - alu_rhs;

    case (FN) 
      A_MINUS_B, B_MINUS_A: Y = alu_sub;
      PASS_A: Y = reg_a;
      PASS_B: Y = reg_b;
      default: Y = 0;
    endcase

    // Status flags
    N = Y[15];
    Z = (Y == 0);

    // Next state logic
    next_state = state;
    case (state)
      OP_A_AWAIT: begin
        if (req) begin
          next_state = OP_A_RELEASE;
        end
      end

      OP_A_RELEASE: begin
        ack = 1;
        if (!req) begin
          next_state = OP_B_AWAIT;
        end
      end

      OP_B_AWAIT: begin
        if (req) begin
          next_state = CALCULATE;
        end
      end

      CALCULATE: begin
        if (Z) begin
          next_state = RESULT_RELEASE;
        end
      end

      RESULT_RELEASE: begin
        if (!req) begin
          next_state = OP_A_AWAIT;
        end
      end

      default: next_state = OP_A_AWAIT;
    endcase
  end

  // Register
  always_ff @(posedge clk) begin
    if (reset) begin
      state   <= OP_A_AWAIT;
      reg_a   <= 0;
      reg_b   <= 0;
      ack     <= 0;
      ABorALU <= 0;
      LDA     <= 0;
      LDB     <= 0;
      FN      <= PASS_A;
      C       <= 0;
    end else begin
      state <= next_state;

      // Default register control
      ack <= 0;
      LDA <= 0;
      LDB <= 0;

      case (state)
        OP_A_AWAIT: begin
          ABorALU <= 0;
          FN <= PASS_A;
          if (req) begin
            LDA   <= 1;
            reg_a <= AB;
            ack   <= 1;
          end
        end

        OP_A_RELEASE: begin
          ABorALU <= 0;
          ack     <= req;
        end

        OP_B_AWAIT: begin
          ABorALU <= 0;
          if (req) begin
            LDB   <= 1;
            reg_b <= AB;
            ack   <= 1;
          end
        end

        CALCULATE: begin
          ABorALU <= 0;
          if (!Z) begin
            if (N) begin
              FN    <= B_MINUS_A;
              LDB   <= 1;
              reg_b <= Y;
            end else begin
              FN    <= A_MINUS_B;
              LDA   <= 1;
              reg_a <= Y;
            end 
          end
        end

        RESULT_RELEASE: begin
          FN      <= PASS_A;
          ABorALU <= 1;
          C       <= reg_a;
          ack     <= 1;
        end
      endcase

      reg_a <= next_reg_a;
      reg_b <= next_reg_b;
    end else begin
    end

  end

endmodule