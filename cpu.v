/*
Group 12
--------
CPU
*/
module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
    
    /* 
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
    
    // TODO: Initialize an array of registers (8x1024) named 'instr_mem' to be used as instruction memory
    
    reg [7:0] instr_mem[0:1023];
    
    // TODO: Create combinational logic to support CPU instruction fetching, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
    assign #2 INSTRUCTION[7:0] = instr_mem[PC];
    assign #2 INSTRUCTION[15:8] = instr_mem[PC+1];
    assign #2 INSTRUCTION[23:16] = instr_mem[PC+2];
    assign #2 INSTRUCTION[31:24] = instr_mem[PC+3];
    
    initial
    begin
        // Initialize instruction memory with the set of instructions you need execute on CPU
        
        // METHOD 1: manually loading instructions to instr_mem
        //{instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]} = 32'b00000000000001000000000000000101;
        //{instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]} = 32'b00000000000000100000000000001001;
        //{instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]} = 32'b00000010000001100000010000000010;
        
        // METHOD 2: loading instr_mem content from instr_mem.mem file
        $readmemb("instr_mem.mem", instr_mem);
    end
    
    /* 
    -----
     CPU
    -----
    */
    cpu mycpu(PC, INSTRUCTION, CLK, RESET);

    initial
    begin
    
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        #1
        RESET = 1'b1;
        
        #5
        RESET = 1'b0; 
        // finish simulation after some time
        #500
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        

endmodule





module cpu(PC, INSTRUCTION, CLK, RESET);
	
	//defining all the inputs,outputs and wires in the CPU
	input [31:0] INSTRUCTION;
	input CLK,RESET;
	output [31:0] PC;
	
	//inputs and outputs for the cu module
	wire [2:0] readreg1,readreg2,writereg,aluop;
	wire subsel,immsel;
	output reg [7:0] subout,immout;
	wire [7:0] immediate;
	wire write_enable;
	
	wire [7:0] regout1,regout2;
	wire [7:0] aluresult;
	
	//instantiate the cu module
	cu mycu(INSTRUCTION,RESET,CLK,readreg1,readreg2,writereg,write_enable,aluop,immediate,subsel,immsel,PC);
	
	//intantiating the reg_file
	reg_file myreg(aluresult,regout1,regout2,writereg,readreg1,readreg2,write_enable,CLK,RESET);
	
	//the mux to select whether to execute add or sub
	always @(subsel,regout2) begin
		if(subsel == 1'b1) #1 subout = ~regout2 +1;
		else if(subsel == 1'b0) subout = regout2;
	end
	
	//the mux to select whether to pass the immediate value or not
	always @(subout,immsel,immediate) begin
		if(immsel == 1'b1) immout = immediate;
		else if(immsel == 1'b0) immout = subout;
	end
	//instantiating the ALU
	alu myalu(regout1,immout,aluresult,aluop);
endmodule

//Control Unit
module cu(INSTRUCTION,RESET,CLK,READREG1,READREG2,WRITEREG,WRITEENABLE,ALUOP,IMMEDIATE,SUB_MUX_SEL,IMM_MUX_SEL,PC);
	//define the inputs and outputs
	input RESET,CLK;
	input [31:0] INSTRUCTION;
	
	output reg [2:0] READREG1,READREG2,WRITEREG,ALUOP;
	output reg SUB_MUX_SEL,IMM_MUX_SEL;
	output reg [7:0] IMMEDIATE;
	output reg [31:0] PC;
	output reg WRITEENABLE;
	
	wire [31:0] current_pc;
	wire [31:0] new_pc;
	
	pc_adder myAdder(PC,new_pc);
	
	//~ assign PC = new_pc;
	
	always @(posedge CLK) begin//at every positive edge of the clock the PC updates
		if(RESET == 1) #1 PC = 0;
		else #1 PC = new_pc;		
	end
	
	always @(INSTRUCTION) begin //whenever a new instruction is fetched, the control signals should change
		
		WRITEENABLE = 1;
		READREG1 = INSTRUCTION[10:8];
		READREG2 = INSTRUCTION[2:0];
		WRITEREG = INSTRUCTION[18:16];
		IMMEDIATE = INSTRUCTION[7:0];
		
		//determining the ALUOP, SUB_MUX_SUM and IMM_MUX_SUM(Generating control signals has a #1 delay)
		
		//ALUOP
		case(INSTRUCTION[26:24])//first 3-bits of the op-code
			3'b000 : ALUOP <= #1 3'b000;
			3'b001 : ALUOP <= #1 3'b000;
			3'b010 : ALUOP <= #1 3'b001;
			3'b011 : ALUOP <= #1 3'b001;
			3'b100 : ALUOP <= #1 3'b010;
			3'b101 : ALUOP <= #1 3'b011;
			default : ALUOP <= #1 3'bzzz;
		endcase	
		
		
		//SUB_MUX_SEL
		case(INSTRUCTION[26:24])//first 3-bits of the op-code
			3'b011 :  SUB_MUX_SEL <= #1 1'b1;
			default :  SUB_MUX_SEL <= #1 1'b0;
		endcase
		
		//IMM_MUX_SEL
		case(INSTRUCTION[26:24])//first 3-bits of the op-code
			3'b000 :  IMM_MUX_SEL <= #1 1'b1;
			default :  IMM_MUX_SEL <= #1 1'b0;
		endcase
				
	end	
	
endmodule





//PC adder
module pc_adder(current,new);
	input [31:0] current;
	output [31:0] new;
	
	assign #1 new = current+4;
endmodule


//ALU
module alu(DATA1,DATA2,RESULT,SELECT);

    input  [7:0] DATA1 ;
    input  [7:0] DATA2 ;//defining inputs and outputs all wires exept for the result register
    input  [2:0] SELECT ;
    output reg [7:0] RESULT;//has to be register type, as RESULT is assigned values in an always @ block

    wire [7:0] forward_out,add_out,and_out,or_out;//wires inside the alu

    FORWARD Forward(DATA2,forward_out);//instantiating modules with individual output wires for each
    ADD Add(DATA1,DATA2,add_out);
    AND And(DATA1,DATA2,and_out) ;
    OR Or(DATA1,DATA2,or_out) ;

   always @ (SELECT,forward_out,add_out,and_out,or_out) begin//run whenever inputs are changed

    case (SELECT)

    3'b000 :  RESULT = forward_out;//assigning the coresponding outputs acording to the SELECT signal
    3'b001 :  RESULT = add_out;
    3'b010 :  RESULT = and_out;
    3'b011 :  RESULT = or_out;
    default :  RESULT =forward_out;
    
    endcase

    end

endmodule
    
module FORWARD(DATA2,RESULT);//module for forwarding the data from port two to RESULT

    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #1 RESULT = DATA2;//continuous assigning of valules to the wire RESULT with an artifitial delay

endmodule

module ADD(DATA1,DATA2,RESULT);//module to add two 8bit data values

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #2 RESULT = DATA1 + DATA2;//addiing the data and continuesly assigning the wire RESULT with an artifitial delay

endmodule

module AND(DATA1,DATA2,RESULT) ;//module for bitwise and operation

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #1 RESULT = DATA1 & DATA2;//ANDing the data and continuesly assigning the wire RESULT with an artifitial delay

endmodule

module OR(DATA1,DATA2,RESULT) ;//module for bitwise or operation

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #1 RESULT = DATA1 | DATA2;//ORing the data and continuesly assigning the wire RESULT with an artifitial delay

endmodule


//Register File
module reg_file(IN,OUT1,OUT2,INADDRESS,OUT1ADDRESS,OUT2ADDRESS, WRITE, CLK, RESET);
//defining inputs and outputs
    input [7:0] IN;
    output [7:0] OUT1;
    output [7:0] OUT2;
    input [2:0] INADDRESS;
    input WRITE;
    input CLK;
    input RESET;
    input [2:0] OUT1ADDRESS;
    input [2:0] OUT2ADDRESS;

    reg [7:0] REG_FILE [7:0] ;//creating the registers(8 8-bit registers)

	//creating int variables to index the reg_file
    integer index_in;
    integer index_out1;
    integer index_out2;
    integer i;

    always @ (INADDRESS,OUT1ADDRESS,OUT2ADDRESS) begin
		/*whenever one of INADDRESS,OUT1ADDRESS,OUT2ADDRESS changes the indexes are assigned to the addresses
		  so that the register can be accessed using the indexes.
		*/
        index_in = INADDRESS;
        index_out1 = OUT1ADDRESS;
        index_out2 = OUT2ADDRESS;
    end

	//continuously assigning the values in the regisers to output ports with a delay of 2 time units.(READING)
    assign #2 OUT1 = REG_FILE[index_out1] ;

    assign #2 OUT2 = REG_FILE[index_out2] ;

    always @ (posedge CLK) begin//at the positive edge of the clock signal
        if (RESET) begin//if reset signal is enabled, assign registers to  all zeros
            for (i=0;i<8;i++) 
				REG_FILE[i] <= #1 8'b0000_0000;//RESET
        end else if (WRITE) begin//if the reset is not enabled and the write is enabled write IN value to the relevent register
            #1 REG_FILE[index_in] <= IN;//WRITE
        end
    end

endmodule
