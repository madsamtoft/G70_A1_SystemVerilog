module gcd_module (
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    input  logic [15:0] AB,
    output logic        ack,
    output logic [15:0] C
);

  logic        N, Z;
  logic        LDA, LDB;
  logic        ABorALU;
  logic [1:0]  fn;


  fsm u_fsm (
    .clk(clk),
    .reset(reset),
    .req(req),
    .N(N),
    .Z(Z),
    .ack(ack),
    .LDA(LDA),
    .LDB(LDB),
    .ABorALU(ABorALU),
    .fn(fn)
  );

  datapath u_datapath (
    .clk(clk),
    .ABorALU(ABorALU),
    .LDA(LDA),
    .LDB(LDB),
    .fn(fn),
    .AB(AB),
    .C(C),
    .Z(Z),
    .N(N)
  );

endmodule