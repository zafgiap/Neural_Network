module regfile #(parameter DATAWIDTH = 32) (output reg [DATAWIDTH-1:0] readData1, output reg [DATAWIDTH-1:0] readData2, output reg [DATAWIDTH-1:0] readData3, output reg [DATAWIDTH-1:0] readData4, input write, input [DATAWIDTH-1:0] writeData1, input [DATAWIDTH-1:0] writeData2, input [3:0] writeReg1, input [3:0] writeReg2, input [3:0] readReg1, input [3:0] readReg2, input [3:0] readReg3, input [3:0] readReg4, input resetn, input clk);
  
  reg [DATAWIDTH-1:0] regs[15:0]; // 16 registers 32 bits wide each
  integer i;
  
  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      for (i=0; i<16; i++)
        regs[i] <= 0;
    end
    else if (write) begin // writing values in memory (we cant read AND write in memory at the same time)
      regs[writeReg1] <= writeData1;
      regs[writeReg2] <= writeData2;
    end
    else begin // reading values from memory
      readData1 <= regs[readReg1];
      readData2 <= regs[readReg2];
      readData3 <= regs[readReg3];
      readData4 <= regs[readReg4];
    end
  end
endmodule
