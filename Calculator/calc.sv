module calc (output [15:0] led, input [15:0] sw, input btnd, input btnr, input btnl, input btnac, input btnc, input clk);
  
  reg [15:0] accumulator;
  reg ovf, zero;
  wire [31:0] ALUresult, op1, op2;
  wire [3:0] alu_op;
  
  calc_enc ALUencoder (alu_op, btnl, btnr, btnd);
  alu calcALU (.ovf(ovf), .result(ALUresult), .zero(zero), .op1(op1), .op2(op2), .alu_op(alu_op));
  
  assign op1 = {{16{accumulator[15]}}, accumulator}; // sign extension, this way we have an intermediate value change due to the sampling of the accumulator
  assign op2 = {{16{sw[15]}}, sw}; // sign extension
  assign led = accumulator;
  
  always @(posedge clk) begin
    if (btnac) begin
      accumulator <= 1'b0;
    end
    else if (btnc) begin
      accumulator <= ALUresult[15:0];
    end
  end
  
endmodule
