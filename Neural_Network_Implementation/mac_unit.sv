module mac_unit #(parameter ALUOP_ADD = 4'b0100, ALUOP_MUL = 4'b0110) (output reg signed [31:0] total_result, output reg zero_mul, output reg zero_add, output reg ovf_mul, output reg ovf_add, input signed [31:0] op1, op2, op3);
  
  reg signed [31:0] mul_result;
  
  alu mul_alu(.ovf(ovf_mul), .result(mul_result), .zero(zero_mul), .op1(op1), .op2(op2), .alu_op(ALUOP_MUL));
  alu add_alu(.ovf(ovf_add), .result(total_result), .zero(zero_add), .op1(mul_result), .op2(op3), .alu_op(ALUOP_ADD));
  
endmodule
