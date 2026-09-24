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
    typedef enum logic [2 : 0] { 
      op_a_await,
      op_a_release,
      op_b_await,
      calculate,
      result_release
    } state_t; // Input your own state names here

    shortint unsigned reg_a, next_reg_a, reg_b, next_reg_b;
    
    state_t state, next_state;
    
    // Combinatorial logic
    always_comb begin
      next_reg_a = reg_a;
      next_reg_b = reg_b;
      next_state = state;
      ack = 0;
      C = 0;

      case (state)
        op_a_await: begin
          if (req && AB != 0) begin
            next_reg_a = AB;
            next_state = op_a_release;
          end
        end

        op_a_release: begin
          ack = 1;
          if (req == 0) begin
            next_state = op_b_await;
          end
        end

        op_b_await: begin
          if (req && AB!= 0) begin
            next_reg_b = AB;
            next_state = calculate;
          end
        end

        calculate: begin
          if (reg_a > reg_b) begin
            next_reg_a = reg_a - reg_b;
          end else if (reg_b > reg_a) begin
            next_reg_b = reg_b - reg_a;
          end else begin
            next_state = result_release;
          end
        end

        result_release: begin
          ack = 1;
          C = reg_a;
          if (req == 0) begin
            next_state = op_a_await;
          end
        end
      endcase
    end

    // Register
    always_ff @(posedge clk) begin
      if (reset) begin
        state <= op_a_await;
        reg_a <= 0;
        reg_b <= 0;
      end else begin
        state <= next_state;
        reg_a <= next_reg_a;
        reg_b <= next_reg_b;
      end
    end

endmodule