`include "REG_FILE.v"
`include "ALU.v"

module cpu(PC, INSTRUCTION, CLK, RESET);

    input CLK,RESET;
    output reg [31:0] PC;//need to store the value of pc to be output 
    input [31:0] INSTRUCTION;

    wire WRITEENABLE;
    wire [31:0] PC_PLUS4;//this wire holds the PC+4 adder's output until the next posedge 
    wire [31:0] PC_NEXT_JUMP;//holds the value of next pc in a jump/beq instruction
    reg [31:0] PC_NEXT;
    wire [2:0] ALUOP;

    wire COMPLEMENT_FLAG;//control signal for the mux 1 (where complemented or original value is choosen)
    wire IMMEDIATE_FALG;//control signal for the mux 2 (where immediate value or mux 1's out is choosen)
    wire BRANCH_FALG;//to be anded with ZERO 
    wire JUMP_FALG;//control signal for the mux4 (choose between immediate value added PC or mux3 out)
    wire ZERO_AND_BRANCHFLAG;//control signal for the mux3 (choose between immediate value added PC or PC+4)
    wire ZERO;//to be used in BEQ instructions
    wire IMMEDIATE_COMPLEMENT_FLAG;//to choose the negated value in a shift left
    
    wire [7:0] REGOUT1;//registerfile out 1
    wire [7:0] REGOUT2;//registerfile out 2
    wire [7:0] COMPLEMENTED_OUT;//output from the 2's complementor
    reg [7:0] COMPLEMENT_MUX_OUT;//output from the mux 1 (complement)
    reg [7:0] IMMEDIATE_MUX_OUT;//output from the mux 2 (immediate)
    reg [7:0] ALU_DATA2;//out from the immediate complement mux
    wire [7:0] IMMEDIATE;//immediate value from the control unit 
    wire [7:0] ALU_RESULT;
    reg [31:0] MUX_3_OUT;//to be used as the fourth mux's input
    wire [31:0] JUMP_IMMEDIATE_FINAL;
    wire [7:0] JUMP_IMMEDIATE_RAW;    

    //register file inputs
    wire [2:0] READREG1;
    wire [2:0] READREG2;
    wire [2:0] WRITEREG;

    //setting the wires for immediate values and reg_file inputs with relevent bits of the instruction
    assign WRITEREG = INSTRUCTION[23:16];
    assign READREG1 = INSTRUCTION[15:8];
    assign READREG2 = INSTRUCTION[7:0];
    assign IMMEDIATE = INSTRUCTION[7:0];
    assign JUMP_IMMEDIATE_RAW =INSTRUCTION[23:16];

    //instantiating the modules control unit, pc adder, reg file, alu and the complementor
    control_unit ctrlUnit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG,BRANCH_FALG,JUMP_FALG);
    pc_adder pcNext(PC,PC_PLUS4);
    pc_adder_jump pcJumpNext(PC_PLUS4,PC_NEXT_JUMP,JUMP_IMMEDIATE_FINAL);
    reg_file regFile(ALU_RESULT,REGOUT1,REGOUT2,WRITEREG,READREG1,READREG2, WRITEENABLE, CLK, RESET);
    alu ALU(REGOUT1,ALU_DATA2,ALU_RESULT,ALUOP,ZERO);
    twosComplement complementor(REGOUT2,COMPLEMENTED_OUT);
    twosComplement complementor_immediate(IMMEDIATE_MUX_OUT,COMPLEMENTED_IMMEDITE);
    
    //assigning the mux3 control (choose between immediate value added PC or PC+4)
    assign ZERO_AND_BRANCHFLAG = ZERO & BRANCH_FALG;

    //left shifting by 2 (as the jump instruction immediate offset comes in terms of instructions) is achived by wiring
    //sign is extended by concatenating the MSB 24 times
    assign JUMP_IMMEDIATE_FINAL= {{22{JUMP_IMMEDIATE_RAW[7]}},JUMP_IMMEDIATE_RAW[7:0],2'b00};
    //                                   ^^                                             ^^
    //                                   ||                                             ||
    //                                 sign extention                               left shifting    
    
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

    always @ (IMMEDIATE_MUX_OUT,COMPLEMENTED_IMMEDIATE,IMMEDIATE_COMPLEMENT_FLAG) begin//mux (where complemented or original value is choosen for immediate value)
        case (IMMEDIATE_COMPLEMENT_FLAG)
            0 : ALU_DATA2 <= IMMEDIATE_MUX_OUT;//immediate mux's output
            1 : ALU_DATA2 <= COMPLEMENTED_IMMEDIATE;//complemented value
        endcase
    end
    
    always @ (PC_NEXT_JUMP,ZERO_AND_BRANCHFLAG,PC_PLUS4) begin//mux 3 (where immediate offset or mux 1's out is choosen)
        case (ZERO_AND_BRANCHFLAG)
            0 : MUX_3_OUT <= PC_PLUS4;//PC + 4 value
            1 : MUX_3_OUT <= PC_NEXT_JUMP;//immediate value added PC
        endcase
    end
    
    always @ (MUX_3_OUT,JUMP_FALG,PC_NEXT_JUMP) begin//mux 4 (where immediate value or mux 1's out is choosen)
        case (JUMP_FALG)
            0 : PC_NEXT <= MUX_3_OUT;//previous mux out
            1 : PC_NEXT <= PC_NEXT_JUMP;//immediate value added PC
        endcase
    end

    always @ (posedge CLK) begin//synchronous reset of the pc
        case(RESET)
            0 : PC <= #1 PC_NEXT;
            1 : PC <= #1 32'b0;
        endcase
    end

endmodule


module control_unit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG,BRANCH_FALG,JUMP_FALG);
    
    input [31:0] INSTRUCTION;
    output reg WRITEENABLE;
    output reg [2:0] ALUOP;
    output reg COMPLEMENT_FLAG;
    output reg IMMEDIATE_FALG;
    output reg BRANCH_FALG;
    output reg JUMP_FALG;
    output reg IMMEDIATE_COMPLEMENT_FLAG;

    wire [7:0] opcode;
    assign opcode = INSTRUCTION[31:24];

    always @ (opcode) begin//control unit decisions ; with simulated decoding delays
        case (opcode)
            8'b0000_0000 : begin//register is written into and an immediate value is chosen in a loadi instruction
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;//doesn't matter 0 or 1
                IMMEDIATE_FALG <=#1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b000;//loadi==>foward                  
            end
            8'b0000_0001 : begin// uncomplemented register file output two is fowarded to be written     
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b000;//mov==>foward 
            end
            8'b0000_0010 : begin//uncomplemented values are added             
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b001;//add==>add
            end
            8'b0000_0011 : begin//complemented values are added    
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b001;//sub==>add
            end
            8'b0000_0100 : begin//uncomplemented reg values are andded 
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b010;//and==>and  
            end
            8'b0000_0101 : begin//uncomplemented values are orred         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                ALUOP <= #1 3'b011;//or==>or    
            end
            8'b0000_0110 : begin//jump instruction ; alu's behaviour doesn't matter
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 1;//jump is set to 1
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b000;    
            end
            8'b0000_0111 : begin//beq instruction ; alu's default add output ZERO is used as a flag (aluop doesn't matter)          
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 1;//branch flag is set to 0
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b001;//beq==>add ; doesn't matter
            end
            ///////////////////////////////////////////////
            // char *op_BNE 	= "00001000";  //EXTENDED ISA  
	        // char *op_ROR 	= "00001001";  //EXTENDED ISA
	        // char *op_SRL 	= "00001010";  //EXTENDED ISA
	        // char *op_SLL 	= "00001011";  //EXTENDED ISA
            // char *op_SRA	= "00001100";  //EXTENDED ISA
            // char *op_MULT	= "00001101";  //EXTENDED ISA
            // 8'b0000_0111 : begin//bne instruction ; alu performs an add operation with the complemented data2 value         
            //     WRITEENABLE <= #1 0;
            //     COMPLEMENT_FLAG <= #1 1;
            //     IMMEDIATE_FALG <= #1 0;
            //     BRANCH_FALG <=#1 1;//branch flag is set to 0
            //     JUMP_FALG <=#1 0;
                // IMMEDIATE_COMPLEMENT_FLAG = #1 0;
            //     ALUOP <= #1 3'b010;//beq==>add
            // end
    // 3'b100 :  RESULT = ror_out;
    // 3'b101 :  RESULT = mul_out;
    // 3'b110 :  RESULT = sra_out;
    // 3'b111 :  RESULT = shiftl_out;

            8'00001001 : begin//ROR instruction ; alu performs an ror operation with the uncomplemented data value         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b100;//ror==>ror
            end
            8'00001010 : begin//srl instruction ; alu performs an add operation with the complemented data2 value         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b111;//srl==>shift_logical
            end
            8'00001011 : begin//sll instruction ; alu performs an add operation with the complemented data2 value         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 1;
                ALUOP <= #1 3'b010;//sll==>shift_logical
            end
            8'00001100 : begin//sra instruction ; alu performs an add operation with the complemented data2 value         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b110;//sra==>sra
            end
            8'00001101 : begin//mult instruction ; alu performs an add operation with the complemented data2 value         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                IMMEDIATE_COMPLEMENT_FLAG = #1 0;
                ALUOP <= #1 3'b101;//mult==>mult
            end
            /////////////////////////////////
            default : begin              
                WRITEENABLE <= #1 1'bz;
                COMPLEMENT_FLAG <= #1 1'bz;
                IMMEDIATE_FALG <= #1 1'bz;
                JUMP_FALG <=#1 1'bz;
                BRANCH_FALG <=#1 1'bz;
                IMMEDIATE_COMPLEMENT_FLAG = #1 1'bz;
                ALUOP <= #1 3'bzzz;    
            end
        endcase  
    end

endmodule

module twosComplement(REGOUT2,COMPLEMENTED_OUT);

    input signed [7:0] REGOUT2;
    output signed [7:0] COMPLEMENTED_OUT;

    assign #1 COMPLEMENTED_OUT = - REGOUT2;

endmodule

module pc_adder(PC,PC_PLUS4);
    input [31:0] PC;
    output [31:0] PC_PLUS4;

    assign #1 PC_PLUS4 = PC + 32'b0100;//MSBs are filled with 0s

endmodule

module pc_adder_jump(PC_PLUS4,PC_NEXT_JUMP,JUMP_IMMEDIATE_FINAL);
    input [31:0] PC_PLUS4;
    input [31:0] JUMP_IMMEDIATE_FINAL;
    output [31:0] PC_NEXT_JUMP;

    assign#2 PC_NEXT_JUMP = PC_PLUS4 + JUMP_IMMEDIATE_FINAL;

endmodule
