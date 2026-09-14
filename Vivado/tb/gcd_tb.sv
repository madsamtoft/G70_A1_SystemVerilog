// -----------------------------------------------------------------------------
//
//  Title      :  System Verilog Testbench for the GCD module
//             :
//  Developers :  Otto Westy Rasmussen
//             :
//  Purpose    :  A testbench for the gcd_top module providing a simulated clock
//             :  and a sequence of test data. This module is written using
//             :  behavioral System Verilog and is only used for testing (can not be
//             :  synthesised)
//             :
//  Revision   : 02203 fall 2025 v.1.0
//
// -----------------------------------------------------------------------------

module gcd_tb ();

  // Period of the clock 
  localparam CLOCK = 20ns;

  // Internal signals
  logic clk, reset;
  logic req, ack;
  logic [15 : 0] AB, C;

  // Instantiate gcd_top module and wire it up to internal signals used for testing
  gcd_top #(
      .n(2)
  ) u_dut (
      .clk  (clk),    // The clock signal.
      .reset(reset),  // Reset the module.
      .req  (req),    // Start computation.
      .AB   (AB),     // The two operands.
      .ack  (ack),    // Computation is complete.
      .C    (C)       // The result.
  );

  // Clock generation (simulation use only)
  initial begin
    clk = 0;
    forever #(CLOCK / 2) clk = ~clk;
  end

  // Provide test input to the entity in the testbench
  localparam N_OPS = 5;

  // Change numbers here if you what to run different tests
  shortint unsigned a_ops[N_OPS - 1 : 0] = '{91, 32768, 49, 29232, 25};
  shortint unsigned b_ops[N_OPS - 1 : 0] = '{63, 272, 98, 488, 5};
  shortint unsigned c_ops[N_OPS - 1 : 0] = '{7, 16, 49, 8, 5};

  initial begin
    // Reset entity for some clock cycles
    reset = 1;
    #(CLOCK * 4);
    reset = 0;
    #CLOCK;

    for (int i = 0; i < N_OPS; i++) begin
      // Supply first operand
      req = 1;
      AB  = a_ops[i];

      // Wait for ack high
      while (ack != 1) begin
        @(posedge clk);
      end

      req = 0;

      // Wait for ack low
      while (ack != 0) begin
        @(posedge clk);
      end

      // Supply second operand
      req = 1;
      AB  = b_ops[i];

      // Wait for ack high
      while (ack != 1) begin
        @(posedge clk);
      end

      // Test the result of the computation
      assert (C == c_ops[i])
      else $error("Wrong result");

      req = 0;

      // Wait for ack low
      while (ack != 0) begin
        @(posedge clk);
      end
    end
    #CLOCK;
    $display("Test succeeded");
    $finish;
  end

  initial begin
    $dumpfile("gcd_tb.vcd");
    $dumpvars();
  end

endmodule
