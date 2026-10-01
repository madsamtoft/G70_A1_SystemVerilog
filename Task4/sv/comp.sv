/* verilator lint_off MULTITOP */

// -----------------------------------------------------------------------------
//
//  Title      :  System Verilog Components for the GCD module
//             :
//  Developers :  Otto Westy Rasmussen
//             :
//  Purpose    :  This design contains models of the components that must be
//             :  used to implement the GCD module.
//             :
//  Note       :  All the components have a generic parameter that sets the
//             :  bit-width of the component. This defaults to 16 bits, so in
//             :  this assignment there is no need to change it.
//             :
//  Revision   :  02203 fall 2025 v.1.0
//
// -----------------------------------------------------------------------------

//------------------------------------------------------------------------------
// A buffer. Defaults to a width of 16 bits. Note the special
// statement that assigns the input to the output. It is similar to a simple
// IF-statement but can be used outside a process.
//------------------------------------------------------------------------------

module c_buf #(
    parameter N = 16
) (
    input  logic [N-1:0] data_in,
    output logic [N-1:0] data_out
);

    assign data_out = data_in;

endmodule

//-------------------------------------------------------------------------------
// A 2 to 1 multiplexor. Defaults to a width of 16 bits.
// If select (s) is 0 input 1 will be choosen else input 2
//-------------------------------------------------------------------------------


module c_mux #(
    parameter N = 16
) (
    input  logic [N-1:0] data_in1,
    input  logic [N-1:0] data_in2,
    input  logic        s,
    output logic [N-1:0] data_out
);

    assign data_out = s ? data_in1 : data_in2;

endmodule

//-------------------------------------------------------------------------------
// A generic positive edge-triggered register with enable. Width defaults to
// 16 bits.
//-------------------------------------------------------------------------------

module c_reg #(
    parameter N = 16
) (
    input  logic          clk,
    input  logic          en,
    input  logic [N-1:0] data_in,
    output logic [N-1:0] data_out
);

    always_ff @(posedge clk) begin
        if (en) begin
            data_out <= data_in;
        end 
    end
endmodule

//-------------------------------------------------------------------------------
// A simple ALU that works on numbers in two's complement representation. The
// width defaults to 16 bits. The ALU has the following four functions encoded
// in the signal "fn":
// fn = 00 : C = A - B
// fn = 01 : C = B - A
// fn = 10 : C = A
// fn = 11 : C = B
// The ALU sets the two flags "Z" and "N" which indicates if the result was zero
// or negative.
//-------------------------------------------------------------------------------


module c_alu #(
    parameter W = 16
) (
    input  logic [W-1:0] A,
    input  logic [W-1:0] B,
    input  logic [1 : 0] fn,
    output logic [W-1:0] C,
    output logic         Z,
    output logic         N
);

    assign C = (fn == 2'b00) ? (A - B) :
               (fn == 2'b01) ? (B - A) :
               (fn == 2'b10) ? (A) : (B);

    assign N = C[W-1];
    assign Z = (C == '0);

endmodule