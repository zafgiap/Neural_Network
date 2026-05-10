module nn #(parameter DATAWIDTH = 32, parameter [3:0] ALUOP_ASR = 4'b0010, ALUOP_ASL = 4'b0011) (output signed [31:0] final_output, output total_ovf, output total_zero, output reg [2:0] ovf_fsm_stage, output reg [2:0] zero_fsm_stage, input enable, input resetn, input clk, input signed [31:0] input_1, input signed [31:0] input_2);
  
  // fsm parameters
  
  localparam [2:0] Deactivated_state = 3'b000;
  localparam [2:0] Loading_Weight_and_Biases = 3'b001;
  localparam [2:0] Data_preprocessing_Layer = 3'b010;
  localparam [2:0] Input_Layer = 3'b011;
  localparam [2:0] Output_Layer = 3'b100;
  localparam [2:0] Data_postprocessing_Layer = 3'b101;
  localparam [2:0] Idle_state = 3'b110;
  
  // for reg file
  
  reg [DATAWIDTH-1:0] readData1, readData2, readData3, readData4;
  reg rf_write;
  reg [DATAWIDTH-1:0] writeData1, writeData2;
  reg [3:0] writeReg1, writeReg2, readReg1, readReg2, readReg3, readReg4;
  
  regfile nn_regfile (readData1, readData2, readData3, readData4, rf_write, writeData1, writeData2, writeReg1, writeReg2, readReg1, readReg2, readReg3, readReg4, resetn, clk);
  
  // for ROM
  
  integer fsm_load_cnt;
  reg rom_ready, total_ovf_fsm;
  reg [7:0] rom_addr1, rom_addr2;
  
  WEIGHT_BIAS_MEMORY ROM(clk, rom_addr1, rom_addr2, writeData1, writeData2);
  
  // FSM 
  
  reg [2:0] current_state, next_state;
  reg signed [DATAWIDTH-1:0] fsm_output, inter_reg1, inter_reg2, inter_reg11;
  reg cnt;
  
  // ALU SHIFT MODULES
  
  wire ovf_shift1, ovf_shift2, zero_shift1, zero_shift2;
  reg [3:0] alu_op_nn;
  reg signed [DATAWIDTH-1:0] sh_op1, sh_op3;
  reg [DATAWIDTH-1:0] sh_op2, sh_op4;
  //reg total_fsm_ovf, total_fsm_zero;
  wire signed [DATAWIDTH-1:0] sh_result_1, sh_result_2;
  //wire result_shift1, result_shift2;
  
  // CREATING THE 2 ALU MODULES
  
  alu shift_alu_1 (ovf_shift1, sh_result_1, zero_shift1, sh_op1, sh_op2, alu_op_nn);
  alu shift_alu_2 (ovf_shift2, sh_result_2, zero_shift2, sh_op3, sh_op4, alu_op_nn);
  
  // INPUT STAGE VARIABLES
  
  wire signed [DATAWIDTH-1:0] mac_result_1, mac_result_2;
  //reg [DATAWIDTH-1:0] mac1_result_copy, mac2_result_copy;
  wire mac1_zero_mul, mac2_zero_mul, mac1_zero_add, mac2_zero_add, mac1_ovf_mul, mac2_ovf_mul, mac1_ovf_add, mac2_ovf_add;
  reg signed [DATAWIDTH-1:0] mac1_op1, mac1_op2, mac1_op3, mac2_op1, mac2_op2, mac2_op3;
  
  // CREATING THE 2 MAC MODULES
  
  mac_unit mac1 (mac_result_1, mac1_zero_mul, mac1_zero_add, mac1_ovf_mul, mac1_ovf_add, mac1_op1, mac1_op2, mac1_op3);
  mac_unit mac2 (mac_result_2, mac2_zero_mul, mac2_zero_add, mac2_ovf_mul, mac2_ovf_add, mac2_op1, mac2_op2, mac2_op3);
  
 // ASSIGNING SOME OF MODULE'S SIGNALS
  
  assign total_ovf = (ovf_shift1 || ovf_shift2 || mac1_ovf_mul || mac2_ovf_mul || mac1_ovf_add || mac2_ovf_add);
  assign total_zero = (zero_shift1 || zero_shift2 || mac1_zero_add || mac2_zero_add);

  assign final_output = fsm_output;

  // OUTPUT STAGE

  wire [DATAWIDTH-1:0] inter_4_5, inter_5;
  
// regfile loading

    always @(posedge clk or negedge resetn) begin
    
    if (!resetn) begin
      rom_addr1 <= 8'd8;
      rom_addr2 <= 8'd12;
      writeReg1 <= 4'd2;
      writeReg2 <= 4'd3;
      rom_ready <= 1'b0;
      fsm_load_cnt <= 1'b0;
	rom_ready <= 0;
    end 
    else if (current_state == Deactivated_state && next_state != Deactivated_state && fsm_load_cnt != 5) begin
	rom_addr1 <= rom_addr1 + 8;
      	rom_addr2 <= rom_addr2 + 8;
   end
    else if (current_state == Loading_Weight_and_Biases && fsm_load_cnt != 5) begin //current_state == Deactivated_state && next_state != Deactivated_state && fsm_load_cnt != 6
      
          fsm_load_cnt <= fsm_load_cnt + 1;
          rom_addr1 <= rom_addr1 + 8;
      	  rom_addr2 <= rom_addr2 + 8;
      	  writeReg1 <= writeReg1 + 2;
      	  writeReg2 <= writeReg2 + 2;
    end
    else begin

	if (current_state == Input_Layer && cnt == 0)
		cnt <= 1;
	else
		cnt <= 0;

        fsm_load_cnt <= 0;
	rom_ready <= 0;
	inter_reg1 <= mac_result_1;
	inter_reg11 <= inter_reg1;
	inter_reg2 <= mac_result_2;
	total_ovf_fsm <= total_ovf;
	
    end   
  end
  
// handling zero result outside the fsm
always @(total_zero) begin

	if (total_zero == 1) begin
		if (current_state == Data_preprocessing_Layer)
			zero_fsm_stage = 3'b010;
		else if (current_state == Input_Layer)
			zero_fsm_stage = 3'b011;
		else if (current_state == Output_Layer && mac1_zero_add == 1)
			zero_fsm_stage = 3'b100;
		else if (current_state == Data_postprocessing_Layer)
			zero_fsm_stage = 3'b101;
	end
	else
		zero_fsm_stage = 3'b111;
end

  // 1st FSM STAGE
  
  always @(posedge clk or negedge resetn) 
    begin: STATE_MEMORY
      if (!resetn) 
        current_state <= Deactivated_state;
      else 
        current_state <= next_state;
    end
  
  // 2nd FSM STAGE
    
  always @(current_state or total_ovf or fsm_load_cnt or enable or cnt)
    begin: NEXT_STATE_LOGIC
      case(current_state)
        Deactivated_state: if (enable)
          			next_state = Loading_Weight_and_Biases;
        		   else
                                next_state = Deactivated_state;
        Loading_Weight_and_Biases: if (!(fsm_load_cnt == 5))
          				next_state = Loading_Weight_and_Biases;
          			   else
            				next_state = Data_preprocessing_Layer;        
        Data_preprocessing_Layer: next_state = Input_Layer;
        Input_Layer: if (total_ovf == 1'b0)
          		next_state = Output_Layer;
        	     else
          		next_state = Idle_state;

        Output_Layer: if (total_ovf == 1'b0) begin
			if (cnt == 1)
				next_state = Output_Layer;
			else
				next_state = Data_postprocessing_Layer;
			end
        	      else
          		next_state = Idle_state;
        Data_postprocessing_Layer: next_state = Idle_state;
        Idle_state: if (enable)
          		next_state = Data_preprocessing_Layer;
        	    else
                        next_state = Idle_state;
      endcase
    end
  
  // 3rd FSM STAGE
  

   always @(current_state or total_ovf or fsm_load_cnt or cnt or total_ovf_fsm)
    begin: OUTPUT_LOGIC
	
// default values of FSM outputs only if total_ovf = 0 OR if we are not in the Input_Layer and Output_Layer --> the first case is used bec if we have total_ovf=1 and we go to Idle we still need to initialize our output fsm variables.

	if ((current_state != Input_Layer && current_state != Output_Layer) || (total_ovf == 0)) begin
	alu_op_nn = ALUOP_ASR;
        fsm_output = 32'b0;
        ovf_fsm_stage = 3'b111;
        rf_write = 1'b0;
        readReg1 = 4'd0;
        readReg2 = 4'd1;
        readReg3 = 4'd0;
        readReg4 = 4'd1;  
        sh_op1 = 1;
        sh_op3 = 1;
        sh_op2 = 0;
        sh_op4 = 0;       
        mac1_op1 = 1; 
        mac1_op2 = 1; 
        mac1_op3 = 1;
            
        mac2_op1 = 1; 
        mac2_op2 = 1; 
        mac2_op3 = 1;
	end

      case(current_state)
        Deactivated_state: begin

	// if enable is on we prepare the regfile to write the first data and continue to the rest
	if (enable)
		rf_write = 1'b1; 

        end
        Loading_Weight_and_Biases: begin
          if (!(fsm_load_cnt == 5)) begin

            rf_write = 1'b1;
            	          
          end
          else begin

            rf_write = 1'b0;
            
            //work for next stage
            
            readReg1 = 4'd2;
            readReg2 = 4'd3;
            
          end
        end
        Data_preprocessing_Layer: begin
          
            sh_op1 = input_1;
            sh_op3 = input_2;
            sh_op2 = readData1;
            sh_op4 = readData2;
   
            readReg1 = 4'd4;
            readReg2 = 4'd5;
            readReg3 = 4'd6;
            readReg4 = 4'd7;
                  
        end
        Input_Layer: begin
            
	if (!total_ovf) begin

// we do this so if ovf exists we will not re-calculate the macx_opy and therefore ruin the initial ovf result due to the default values of shift that got passed the 1st time where ovf=0!!!

            mac1_op1 = sh_result_1; 
            mac1_op2 = readData1; 
            mac1_op3 = readData2;
            
            mac2_op1 = sh_result_2; 
            mac2_op2 = readData3; 
            mac2_op3 = readData4;      

            readReg1 = 4'd8;
            readReg3 = 4'd9; 
            readReg4 = 4'd10; 

          end
	  else if (total_ovf) begin

	// if we have overflow then we will immediately go to idle state with fsm_output = -1

            ovf_fsm_stage = 3'b011;
            fsm_output = -1;
	  end

        end
        Output_Layer: begin
	
	if (!total_ovf) begin

	if (cnt == 1) begin
            mac2_op1 = inter_reg2; 
            mac2_op2 = readData3; 
            mac2_op3 = readData4;       
            mac1_op1 = 1; 
            mac1_op2 = 1; 
            mac1_op3 = 1;  
 

	end
	else begin 

// Only the result of the second mac_unit matters if it is zero, so check for zero iss done only when the mac1 works which will produce the inter_5 result. If inter_5 is 0 then total_zero = 1
         
            mac1_op1 = inter_reg11; 
            mac1_op2 = readData1; 
            mac1_op3 = inter_reg2; 
            mac2_op1 = 1; 
            mac2_op2 = 1; 
            mac2_op3 = 1;           

        end

	  readReg1 = 4'd8;
	  readReg2 = 4'd11;

	end
	else if (total_ovf) begin
      
	    ovf_fsm_stage = 3'b100;
            fsm_output = -1;

	end
   
        end
        Data_postprocessing_Layer: begin

          alu_op_nn = ALUOP_ASL;
          sh_op1 = mac_result_1;
          sh_op2 = readData2;

        end
          Idle_state: begin

	  if (total_ovf_fsm) begin

	  fsm_output = -1;

            mac1_op1 = 32'h7fffffff; 
            mac1_op2 = 32'h7fffffff; 
            mac1_op3 = 32'h7fffffff;
            
            mac2_op1 = 32'h7fffffff; 
            mac2_op2 = 32'h7fffffff; 
            mac2_op3 = 32'h7fffffff; 
	  
	end
	else if (!total_ovf_fsm) begin

	  fsm_output = sh_result_1;

	end

// result remains because if state doesnt change (or something in the sensitivity list) then we never go inside idle again and outputs remain
// ensuring final_output stays -1 until enable is again 1 and new calculations begin - for the result to remain the ovf value of -1, we dont want the total_ovf to change to 0 and ruin the final result, we keep it overflowed till new inputs arrive

	  readReg1 = 4'd2;
          readReg2 = 4'd3;

          end
          default: begin
          alu_op_nn = ALUOP_ASR;
          fsm_output = 32'b0;
          ovf_fsm_stage = 3'b111;
          rf_write = 1'b0;
          readReg1 = 4'd0;
          readReg2 = 4'd1;
          readReg3 = 4'd0;
          readReg4 = 4'd1;  
            sh_op1 = 1;
            sh_op3 = 1;
            sh_op2 = 0;
            sh_op4 = 0;       
            mac1_op1 = 1; 
            mac1_op2 = 1; 
            mac1_op3 = 1;
            
            mac2_op1 = 1; 
            mac2_op2 = 1; 
            mac2_op3 = 1; 

          end
       endcase
    end         
  
endmodule
