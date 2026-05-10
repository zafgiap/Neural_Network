module alu #(parameter [3:0] ALUOP_SUB = 4'b0101, ALUOP_MUL = 4'b0110, ALUOP_ADD = 4'b0100, ALUOP_LSR = 4'b0000, ALUOP_LSL = 4'b0001, ALUOP_ASR = 4'b0010, ALUOP_ASL = 4'b0011, ALUOP_XOR = 4'b1100, ALUOP_NAND = 4'b1011, ALUOP_NOR = 4'b1010, ALUOP_OR = 4'b1001, ALUOP_AND = 4'b1000) (output reg ovf, output reg [31:0] result, output reg zero, input signed [31:0] op1, input signed [31:0] op2, input [3:0] alu_op);
  
  reg signed [63:0] pre_result;
    
  always @(*) begin
    
    case (alu_op) 	
   
	ALUOP_LSR: pre_result = $unsigned(op1) >> op2;
	ALUOP_LSL: pre_result = op1 << op2;
	ALUOP_ASR: pre_result = op1 >>> op2;
	ALUOP_ASL: pre_result = op1 <<< op2;
	ALUOP_ADD: pre_result = op1 + op2;
	ALUOP_SUB: pre_result = op1 - op2;
	ALUOP_MUL: pre_result = op1 * op2;
	ALUOP_XOR: pre_result = op1 ^ op2;
	ALUOP_NAND: pre_result = ~(op1 & op2);
	ALUOP_NOR: pre_result = ~(op1 | op2);
	ALUOP_OR: pre_result = op1 | op2;
	ALUOP_AND: pre_result = op1 & op2;
	default: pre_result = 64'sd0;

  endcase

    result = pre_result[31:0]; //using the lower 32 bits (we use 64 bit pre_result to handle the multiplication overflow)
    
    // handling ovf
    if (alu_op == ALUOP_ADD)
      ovf = ((op1[31] == op2[31]) && (result[31] != op1[31])?1:0);
    else if (alu_op == ALUOP_SUB)
      ovf = ((op1[31] != op2[31]) && (result[31] != op1[31])?1:0);
    else if (alu_op == ALUOP_MUL) 
      ovf = (!(pre_result[63:32] == {32{pre_result[31]}}));
    else
      ovf = 0;
    
    // handling zero
    zero = (result == 32'b0);
    
  end
  
    
endmodule
