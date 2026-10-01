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
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    input  logic [15:0] AB,
    output logic        ack,
    output logic [15:0] C
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
    logic [15:0] reg_a, next_reg_a;
    logic [15:0] reg_b, next_reg_b;
    logic [15:0] sub_left, sub_right;
    logic [15:0] difference;
    logic        borrow;

    always_comb begin
        next_state = state;
        next_reg_a = reg_a;
        next_reg_b = reg_b;

        ack = 1'b0;
        C   = reg_a;

        // Select the order of the subtraction
        sub_left  = reg_a;
        sub_right = reg_b;
        if (state == subtract_b) begin
            sub_left  = reg_b;
            sub_right = reg_a;
        end

        difference = sub_left - sub_right;

        // Determine unsigned borrow using MSBs
        borrow = (sub_left[15] ^ sub_right[15]) ? sub_right[15] : difference[15];

        case (state)
          op_a_await: begin
            if (req) begin
              next_reg_a = AB;
              next_state = op_a_release;
            end
          end

        op_a_release: begin
          ack = 1'b1;
          if (!req)
            next_state = op_b_await;
        end

        op_b_await: begin
          if (req) begin
            next_reg_b = AB;
            next_state = calculate;
          end
        end

        calculate: begin
          if (difference == 16'd0)
            next_state = result_release;
          else if (borrow)
            next_state = subtract_b;
          else
            next_reg_a = difference;
        end

        subtract_b: begin
          next_reg_b = difference;
          next_state = calculate;
        end

        result_release: begin
          ack = 1'b1;
          if (!req)
            next_state = op_a_await;
        end

        default: begin
          next_state = op_a_await;
        end
      endcase
    end

  always_ff @(posedge clk) begin
    if (reset) begin
      state <= op_a_await;
      reg_a <= 16'd0;
      reg_b <= 16'd0;
    end else begin
      state <= next_state;
      reg_a <= next_reg_a;
      reg_b <= next_reg_b;
    end
  end
endmodule