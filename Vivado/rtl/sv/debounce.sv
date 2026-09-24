// -----------------------------------------------------------------------------
//
//  Title      :  System Verilog debouncer
//             :
//  Developers :  Otto Westy Rasmussen
//             :
//  Purpose    :  Debouncer for mechanical switches on Nexys A7-100T board
//             :
//  Revision   : 02203 fall 2025 v.2.0
//
// -----------------------------------------------------------------------------

module debounce #(
    parameter n = 20  // filter of 2^n * 10ns = 10ms
) (                   // n should be set to 20 when synthesizing and 2 when simulating.
    input  logic clk,
    input  logic reset,
    input  logic sw,
    output logic db_level,
    output logic db_tick
);

  typedef enum logic [1 : 0] {
    zero,
    wait0,
    one,
    wait1
  } state_t;
  state_t state_reg, state_next;
  logic unsigned [n-1:0] q_reg, q_next;
  logic q_load, q_dec, q_zero;
  logic sw_reg1, sw_reg2;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      sw_reg1 <= 0;
      sw_reg2 <= 0;
    end else begin
      sw_reg2 <= sw_reg1;
      sw_reg1 <= sw;
    end
  end

  // fsmd state & data registers
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state_reg <= zero;
      q_reg     <= 0;
    end else begin
      state_reg <= state_next;
      q_reg     <= q_next;
    end
  end

  // fsmd data path (counter) next-state logic
  always_comb begin
    if (q_load) begin
      q_next = {n{1'b1}};
    end else if (q_dec) begin
      q_next = q_reg - 1;
    end else begin
      q_next = q_reg;
    end

    if (!q_next) begin
      q_zero = 1;
    end else begin
      q_zero = 0;
    end
  end

  // fsmd control path next-state logic
  always_comb begin

    q_load     = 0;
    q_dec      = 0;
    db_level   = 0;
    db_tick    = 0;
    state_next = state_reg;

    case (state_reg)
      zero: begin
        db_level = 0;
        if (sw_reg2) begin
          state_next = wait1;
          q_load     = 1;
        end
      end

      wait1: begin
        db_level = 0;
        if (sw_reg2) begin
          q_dec = 1;
          if (q_zero) begin
            state_next = one;
            db_tick    = 1;
          end
        end else begin
          state_next = zero;
        end
      end

      one: begin
        db_level = 1;
        if (!sw_reg2) begin
          state_next = wait0;
          q_load     = 1;
        end
      end

      wait0: begin
        db_level = 1;
        if (!sw_reg2) begin
          q_dec = 1;
          if (q_zero) begin
            state_next = zero;
          end
        end else begin
          state_next = one;
        end
      end
    endcase
  end

endmodule
