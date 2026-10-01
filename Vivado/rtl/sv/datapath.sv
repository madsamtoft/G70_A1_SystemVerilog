module datapath (
    input  logic        clk,
    input  logic        ABorALU,
    input  logic        LDA, LDB,
    input  logic [1:0]  fn,
    input  logic [15:0] AB,
    output logic [15:0] C,
    output logic        Z, N
);

  // Internal Signals
  logic [15:0] Y;
  logic [15:0] C_int;
  logic [15:0] RegA, RegB;

  // Component Instances
  c_mux u_mux (
    .data_in1 (Y),
    .data_in2 (AB),
    .s        (ABorALU),
    .data_out (C_int)
  );

  c_reg u_reg_a (
    .clk      (clk),
    .en       (LDA),
    .data_in  (C_int),
    .data_out (RegA)
  );
  
  c_reg u_reg_b (
    .clk      (clk),
    .en       (LDB),
    .data_in  (C_int),
    .data_out (RegB)
  );

  c_alu u_alu (
    .A  (RegA),
    .B  (RegB),
    .fn (fn),
    .C  (Y),
    .Z  (Z),
    .N  (N)
  );

  c_buf u_buf (
    .data_in  (RegA),
    .data_out (C)
  );

endmodule