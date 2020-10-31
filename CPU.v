`include "REG_FILE.v"
`include "ALU.v"

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

    input CLK,RESET;
    output reg [31:0] PC;//need to store the value of pc to be output 
    input [31:0] INSTRUCTION;
    integer i; //this used to refer the indexes when sign extension happens 

    wire WRITEENABLE;
    wire [31:0] PC_4;//PC+4
    wire [31:0] PC_NEXT;
    reg signed [31:0] EXTENDED;
    wire signed [7:0] OFFSET;
    wire [2:0] ALUOP;
    wire COMPLEMENT_FLAG;//control signal for the mux 1 (where complemented or original value is choosen)
    wire IMMEDIATE_FALG;//control signal for the mux 2 (where immediate value or mux 1's out is choosen)
    wire [7:0] REGOUT1;//registerfile out 1
    wire [7:0] REGOUT2;//registerfile out 2
    wire [7:0] COMPLEMENTED_OUT;//output from the 2's complementor
    reg [7:0] COMPLEMENT_MUX_OUT;//output from the mux 1 (complement)
    reg [7:0] IMMEDIATE_MUX_OUT;//output from the mux 2 (immediate)
    reg [31:0] J_MUX_OUT;
    reg [31:0] B_MUX_OUT;
    wire [7:0] IMMEDIATE;//immediate value from the control unit 
    wire [7:0] ALU_RESULT;
    wire ZERO;
    wire J_FLAG;
    wire B_FLAG;
    wire B_ENABLE;

    //register file inputs
    wire [2:0] READREG1;
    wire [2:0] READREG2;
    wire [2:0] WRITEREG;

    //setting the wires for immediate value and reg_file inputs with relevent bits of the instruction
    assign WRITEREG = INSTRUCTION[23:16];
    assign READREG1 = INSTRUCTION[15:8];
    assign READREG2 = INSTRUCTION[7:0];
    assign IMMEDIATE = INSTRUCTION[7:0];
    assign OFFSET = INSTRUCTION[23:16];
	
    //instantiating the modules control unit, pc adder, reg file, alu and the complementor
    control_unit ctrlUnit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG,J_FLAG,B_FLAG);
    pc_adder pcNext(PC,PC_4);
    reg_file regFile(ALU_RESULT,REGOUT1,REGOUT2,WRITEREG,READREG1,READREG2, WRITEENABLE, CLK, RESET);
    alu ALU(REGOUT1,IMMEDIATE_MUX_OUT,ALU_RESULT,ALUOP,ZERO);
    twosComplement complementor(REGOUT2,COMPLEMENTED_OUT);

    always @ (REGOUT2,COMPLEMENTED_OUT,COMPLEMENT_FLAG) begin//mux 1 (where complemented or original value is choosen)
        case (COMPLEMENT_FLAG)
            0 : COMPLEMENT_MUX_OUT <= REGOUT2;//original value
            1 : COMPLEMENT_MUX_OUT <= COMPLEMENTED_OUT;//complemented value
        endcase
    end

    always @ (COMPLEMENT_MUX_OUT,IMMEDIATE_FALG,IMMEDIATE) begin//mux 2 (where immediate value or mux 1's out is choosen)
        case (IMMEDIATE_FALG)
            0 : IMMEDIATE_MUX_OUT <= COMPLEMENT_MUX_OUT;//previous mux out
            1 : IMMEDIATE_MUX_OUT <= IMMEDIATE;//immediate value
        endcase
    end
    
    always @ (J_FLAG,PC_NEXT,B_MUX_OUT) begin
		case (J_FLAG)
			0: J_MUX_OUT = B_MUX_OUT;
			1: J_MUX_OUT = PC_NEXT;
		endcase
    end
    //assign j_MUX_OUT = (J_FLAG)? B_MUX_OUT : PC_4;
    assign B_ENABLE = ZERO & B_FLAG;
    
    always @ (B_ENABLE,PC_4,PC_NEXT) begin //the mux which chooses PC+4 or the updated PC value after a jump
		case(B_ENABLE)
			0: B_MUX_OUT = PC_4;
			1: B_MUX_OUT = PC_NEXT;
		endcase
    end

    always @ (posedge CLK) begin//synchronous reset of the pc
        case(RESET)
            0 : PC <= #1 J_MUX_OUT;//previously it was PC_4
            1 : PC <= #1 32'b0;
        endcase
    end
    
    //Calculating 4*number_of_instructions + (PC+4)
    always @ (OFFSET) begin
		EXTENDED[0] <= 1'b0;
		EXTENDED[1] <= 1'b0;
		
		for(i = 2 ; i<=9 ; i++)
			EXTENDED[i] <= OFFSET[i-2];
			
		for(i=10 ; i<=31 ; i++)
			EXTENDED[i] <= OFFSET[7];
		 
    end
    
    /*
    always @ (OFFSET) begin
		for(i = 0 ; i<=21 ; i++)
			EXTENDED[i] <= OFFSET[0];
			
		for(i=22 ; i<=29 ; i++)
			EXTENDED[i] <= OFFSET[i-22];
		 
		EXTENDED[30] <= 1'b0;
		EXTENDED[31] <= 1'b0;
    end
    */
    
    assign #2 PC_NEXT = PC_4 + EXTENDED;
    
    /*
     always @ (EXTENDED) begin
		PC_NEXT = #2 PC_4 + EXTENDED;
    end
    */
      
endmodule


module control_unit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG,J_FLAG,B_FLAG);
    
    input [31:0] INSTRUCTION;
    output reg WRITEENABLE;
    output reg [2:0] ALUOP;
    output reg COMPLEMENT_FLAG;
    output reg IMMEDIATE_FALG;
    output reg J_FLAG;
    output reg B_FLAG;

    wire [7:0] opcode;
    assign opcode = INSTRUCTION[31:24];//decoding delay

    always @ (opcode) begin//control unit decisions
        case (opcode)
            8'b0000_0000 : begin//register is written into and an immediate value is chosen in a loadi instruction
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;//doesn't matter 0 or 1
                IMMEDIATE_FALG <=#1 1;
                ALUOP <= #1 3'b000;//loadi==>foward
                J_FLAG <= #1 0;
                B_FLAG <= #1 0;                  
            end
            8'b0000_0001 : begin// uncomplemented register file output two is fowarded to be written     
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b000;//mov==>foward
                J_FLAG <= #1 0;
                B_FLAG <= #1 0; 
            end
            8'b0000_0010 : begin//uncomplemented values are added             
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b001;//add==>add
                J_FLAG <= #1 0;
                B_FLAG <= #1 0;
            end
            8'b0000_0011 : begin//complemented values are added    
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b001;//sub==>add
                J_FLAG <= #1 0;
                B_FLAG <= #1 0;
            end
            8'b0000_0100 : begin//uncomplemented reg value is andded 
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b010;//and==>and
                J_FLAG <= #1 0;
                B_FLAG <= #1 0;  
            end
            8'b0000_0101 : begin//uncomplemented values are orred         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b011;//or==>or 
                J_FLAG <= #1 0;
                B_FLAG <= #1 0;   
            end
            
            8'b0000_0110 : begin//J         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b011; 
                J_FLAG <= #1 1;
                B_FLAG <= #1 0;  
            end
            
            8'b0000_0111 : begin//beq         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b001;
                J_FLAG <= #1 0;
                B_FLAG <= #1 1;    
            end
            default : begin              
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b000;
                J_FLAG <= #1 0;
                B_FLAG <= #1 0;    
            end
        endcase  
    end

endmodule

module twosComplement(REGOUT2,COMPLEMENTED_OUT);

    input signed [7:0] REGOUT2;
    output signed [7:0] COMPLEMENTED_OUT;

    assign #1 COMPLEMENTED_OUT = - REGOUT2;

endmodule

module pc_adder(PC,PC_NEXT);
    input [31:0] PC;
    output [31:0] PC_NEXT;

    assign #2 PC_NEXT = PC + 32'b0100;//MSBs are filled with 0s

endmodule
