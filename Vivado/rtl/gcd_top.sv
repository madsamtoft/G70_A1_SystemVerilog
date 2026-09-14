// -----------------------------------------------------------------------------
//
//  Title      :  Specification of GCD entity
//             :
//  Developers :  Otto Westy Rasmussen
//             :
//  Purpose    :  Specification of gcd_top
//             :
//  Revision   :  02203 fall 2025 v.1.0
//
//------------------------------------------------------------------------------
// The GCD-module computes the greatest common divisor of two integers
// The module behaves as an SLT-module with handshake signals "req" and "ack".
// "req" and "ack" follow a 4-phase fully interlocked handshake protocol.
//
// A computation involves two handshakes.
//   (1) During the first handshake the operand A is input.
//   (2) During the second the B operand is input, the computation is performed and
//       the result C is output.
//------------------------------------------------------------------------------

module gcd_top #(
    parameter n = 0  //  Not used in task 1
) (
    input logic          clk,    // The clock signal.
    input logic          reset,  // Reset the module.
    input logic          req,    // Start computation.
    input logic [15 : 0] AB,     // The two operands. One at a time.

    output logic ack,
    output logic [15 : 0] C
);

  shortint unsigned RegA;
  shortint unsigned RegB;

  initial begin
    ack = 0;
    C   = 'z;

    // An endless loop.
    forever begin
      // First handshake: Input of A operand

      // Handshake phase 1.
      @(posedge req);

      // The operand is stored in the register.
      RegA = AB;

      // Handshake phase 2.
      ack  = #15ns 1;

      // Handshake phase 3.
      @(negedge req);

      // Handshake phase 4. Handshake protocol complete.
      ack = #5ns 0;


      // Second handshake: Input of B operand, computation and output of result

      // Handshake phase 1.
      @(posedge req);

      // The operand is stored in the register.
      RegB = AB;

      // The operand is stored in the register.
      while (RegA != RegB) begin
        if (RegA > RegB) begin
          RegA = RegA - RegB;
        end else begin
          RegB = RegB - RegA;
        end
      end

      // Outpuut the result after a small delay. The delay makes the waveforms
      // for a simulation easier to read.
      C   = #15ns RegA;

      // Handshake phase 2.
      ack = #15ns 1;

      // Handshake phase 3.
      @(negedge req);

      // Handshake phase 4. Handshake protocol complete. Remove result from 
      // output.
      ack = #5ns 0;
      C   = 'Z;
    end
  end
endmodule
