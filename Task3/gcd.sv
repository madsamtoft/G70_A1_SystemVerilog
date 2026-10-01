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
        result_release
    } state_t;

    state_t state, next_state;
    logic [15:0] reg_a, next_reg_a;
    logic [15:0] reg_b, next_reg_b;
    logic [3:0]  common_shift, next_common_shift;
    logic [15:0] sub_left, sub_right;
    logic [15:0] difference;
    logic [15:0] result_base;
    logic        a_gt_b, both_odd;
    logic [15:0] normalize_input, normalized_value, normalized_b;
    logic [3:0]  normalize_shift, b_shift, shared_shift;

    // Count trailing zeros of a nonzero 16-bit value (return zero for zero)
    function automatic logic [3:0] ctz16(input logic [15:0] value);
      logic [15:0] bits_left;
      logic [3:0] count;
      begin
        bits_left = value;
        count = 4'd0;
        if (bits_left[7:0] == 8'd0) begin
          count[3] = 1'b1;
          bits_left = bits_left >> 8;
        end
        if (bits_left[3:0] == 4'd0) begin
          count[2] = 1'b1;
          bits_left = bits_left >> 4;
        end
        if (bits_left[1:0] == 2'd0) begin
          count[1] = 1'b1;
          bits_left = bits_left >> 2;
        end
        if (!bits_left[0])
          count[0] = 1'b1;
        ctz16 = (value == 16'd0) ? 4'd0 : count;
      end
    endfunction

    always_comb begin
        next_state = state;
        next_reg_a = reg_a;
        next_reg_b = reg_b;
        next_common_shift = common_shift;

        ack = 1'b0;
        C   = reg_a;
        result_base = reg_a;

        // Select larger minus smaller for one shared subtractor.
        a_gt_b = (reg_a > reg_b);
        sub_left  = a_gt_b ? reg_a : reg_b;
        sub_right = a_gt_b ? reg_b : reg_a;
        difference = sub_left - sub_right;

        // Share one normalization lane between A and the odd-pair difference.
        both_odd = reg_a[0] && reg_b[0];
        normalize_input = both_odd ? difference : reg_a;
        normalize_shift = ctz16(normalize_input);
        normalized_value = normalize_input >> normalize_shift;

        // A second lane allows both initial operands to normalize together.
        b_shift = ctz16(reg_b);
        normalized_b = reg_b >> b_shift;
        shared_shift = (normalize_shift < b_shift) ? normalize_shift : b_shift;

        case (state)
          op_a_await: begin
            if (req) begin
              next_reg_a = AB;
              next_common_shift = 4'd0;
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
          // Detect completion independently of subtractor
          if ((reg_a == 16'd0) || (reg_b == 16'd0) ||
              (reg_a == reg_b) ||
              (reg_a == 16'd1) || (reg_b == 16'd1)) begin
            if (reg_a == 16'd0)
              result_base = reg_b;
            else if (reg_b == 16'd0)
              result_base = reg_a;
            else if ((reg_a == 16'd1) || (reg_b == 16'd1))
              result_base = 16'd1;

            // Restore common power of two into existing result register.
            next_reg_a = result_base << common_shift;
            next_state = result_release;
          end else if (!both_odd) begin
            // Normalize both operands fully
            next_reg_a = normalized_value;
            next_reg_b = normalized_b;
            next_common_shift = shared_shift;
          end else begin
            if (a_gt_b)
              next_reg_a = normalized_value;
            else
              next_reg_b = normalized_value;
          end
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
      common_shift <= 4'd0;
    end else begin
      state <= next_state;
      reg_a <= next_reg_a;
      reg_b <= next_reg_b;
      common_shift <= next_common_shift;
    end
  end
endmodule