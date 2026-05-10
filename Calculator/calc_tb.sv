// `timescale 1ns/1ps;

module testbench;
  
  reg btnl, btnr, btnd, btnac, btnc, clk;
  reg [15:0] sw;
  wire [15:0] led;
  
  calc DUT (led, sw, btnd, btnr, btnl, btnac, btnc, clk);
  
  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, testbench);
    
    clk = 1'b0;
    
    btnac = 1'b1;
    btnc = 1'b0;
    #2;
    btnac = 1'b0;
    btnc = 1'b1;
    #4;
    btnl = 0;
    btnr = 1;
    btnd = 0;
    sw = 16'h285a;
    #2;
    btnc = 1'b0;
    #8;
    btnc = 1'b1;
    btnl = 1;
    btnr = 1;
    btnd = 1;
    sw = 16'h04c8;
    #2;
    btnc = 1'b0;
    #8;
    btnc = 1'b1;
    btnl = 0;
    btnr = 0;
    btnd = 0;
    sw = 16'h0005;
    #2;
    btnc = 1'b0;
    #8;
    btnc = 1'b1;
    btnl = 1;
    btnr = 0;
    btnd = 1;
    sw = 16'ha085;
    #2;
    btnc = 1'b0;
    #8;
    btnc = 1'b1;
    btnl = 1;
    btnr = 0;
    btnd = 0;
    sw = 16'h07fe;
    #2;
    btnc = 1'b0;
    #8;
    btnc = 1'b1;
    btnl = 0;
    btnr = 0;
    btnd = 1;
    sw = 16'h0004;
    #2;
    btnc = 1'b0;
    #8;
    btnc = 1'b1;
    btnl = 1;
    btnr = 1;
    btnd = 0;
    sw = 16'hfa65;
    #2;
    btnc = 1'b0;
    #8;
    btnc = 1'b1;
    btnl = 0;
    btnr = 1;
    btnd = 1;
    sw = 16'hb2e4;
    #2;
    btnc = 1'b0;
    #10;
    btnac = 1'b1;
    btnc = 1'b0;
    #8;
    
   $finish;
    
  end
    
    always begin
      #1 clk = ~clk;
    end
      
  
endmodule
    
    
