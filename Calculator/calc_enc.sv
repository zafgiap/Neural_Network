module calc_enc (output [3:0] alu_op, input btnl, input btnr, input btnd);
  
  wire A1, A2, A3, A4, A5, A6, A7, A8, A9;
  wire B1, B2, B3, B4, B5;
  wire C1;
  
  // FOR alu_op[0]
  // NOT'S
  not Not1 (A1, btnl);
  not Not2 (A3, btnd);
  
  // AND'S
  and And1 (A2, btnl, btnr);
  and And2 (B2, A2, A3);
  and And3 (B1, A1, btnd);
  
  // OR
  or OR1 (alu_op[0], B1, B2);
  
  // FOR alu_op[1]
  // NOT'S
  not Not3 (A4, btnr);
  not Not4 (A5, btnd);
  
  // AND'S
  and And4 (alu_op[1], btnl, B3);
  
  //OR
  or OR2 (B3, A4, A5);
  
  // FOR alu_op[2]
  // NOT'S
  not Not5 (A6, btnl);
  not Not6 (B4, A7);
  
  // AND'S
  and And5 (B5, A6, btnr);
  and And6 (C1, btnl, B4);
  
  // OR
  or OR3 (alu_op[2], C1, B5);
  
  // XOR
  xor XOR1 (A7, btnr, btnd);
  
  // FOR alu_op[3]
  // AND'S
  
  and AND6 (A8, btnl, btnr);
  and AND7 (A9, btnl, btnd);
  
  // OR
  or OR4 (alu_op[3], A8, A9);
  
endmodule 
