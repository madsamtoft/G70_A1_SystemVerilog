// -----------------------------------------------------------------------------
//
//  Title      :  Implementation of the GCD with debouncer
//             :
//  Developers :  Otto Westy Rasmussen
//             :
//  Purpose    :  This design instantiates a debouncer and an implementation of GCD
//             :
//  Revision   :  02203 fall 2025 v.1.0
//
// -----------------------------------------------------------------------------

module gcd_top #(
    parameter n = 20
) (
    input  logic          clk,    // The clock signal.
    input  logic          reset,  // Reset the module.   
    input  logic          req,    // Start computation.
    input  logic [15 : 0] AB,     // The two operands. One at a time.
    output logic          ack,    // Input received / Computation is complete.
    output logic [15 : 0] C       // The result.
);

  logic db_req;

  debounce #(
      .n(n)
  ) u_debounce (
      .clk     (clk),
      .reset   (reset),
      .sw      (req),
      .db_level(db_req),
      .db_tick ()
  );

  gcd u_gcd (
      .clk  (clk),     // The clock signal.
      .reset(reset),   // Reset the module.
      .req  (db_req),  // Input operand / Start computation.
      .AB   (AB),      // Bus for a and b operands.
      .ack  (ack),     // Input received / Computation is complete.
      .C    (C)        // The result.
  );

endmodule
