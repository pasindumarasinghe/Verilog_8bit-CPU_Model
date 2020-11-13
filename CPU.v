`include "REG_FILE.v"
`include "ALU.v"
 
module cpu(PC, INSTRUCTION,CLK, RESET, READ, WRITE, ADDRESS, WRITE_DATA, READ_DATA, BUSYWAIT);

    input CLK,RESET;
    output reg [31:0] PC;//need to store the value of pc to be output 
    input [31:0] INSTRUCTION;
    output WRITE;//memory control signal for writing
    output READ;//memory control signal for reading
    input BUSYWAIT;//control signal from memory busy  
    output [7:0] WRITE_DATA;//data to be written to memory
    input [7:0] READ_DATA;//data read from memory

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
    wire LOAD_WORD_FLAG;//mux control signal for choosing alu data or emory data
    
    wire [7:0] REGOUT1;//registerfile out 1
    wire [7:0] REGOUT2;//registerfile out 2
    wire [7:0] COMPLEMENTED_OUT;//output from the 2's complementor
    reg [7:0] COMPLEMENT_MUX_OUT;//output from the mux 1 (complement)
    reg [7:0] IMMEDIATE_MUX_OUT;//output from the mux 2 (immediate)
    wire [7:0] IMMEDIATE;//immediate value from the control unit 
    wire [7:0] ALURESULT;//output of the alu
    reg [7:0] REG_FILE_DATA_IN;//mux 5 out to the reg file    
    reg [31:0] MUX_3_OUT;//to be used as the fourth mux's input
    wire [31:0] JUMP_IMMEDIATE_FINAL;//shifted and sign extended jump immediate value
    wire [7:0] JUMP_IMMEDIATE_RAW;//raw immediate jump offset
    output [7:0] ADDRESS;//addtress to read/write data

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
    control_unit ctrlUnit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG,BRANCH_FALG,JUMP_FALG,WRITE,READ,LOAD_WORD_FLAG,BUSYWAIT);
    pc_adder pcNext(PC,PC_PLUS4);
    pc_adder_jump pcJumpNext(PC_PLUS4,PC_NEXT_JUMP,JUMP_IMMEDIATE_FINAL);
    reg_file regFile(REG_FILE_DATA_IN,REGOUT1,REGOUT2,WRITEREG,READREG1,READREG2, WRITEENABLE, CLK, RESET,BUSYWAIT);
    alu ALU(REGOUT1,IMMEDIATE_MUX_OUT,ALURESULT,ALUOP,ZERO);
    twosComplement complementor(REGOUT2,COMPLEMENTED_OUT);

    //memory address
    assign ADDRESS = ALURESULT;

    //data to be written to memory
    assign WRITE_DATA = REGOUT1;

    //assigning the mux3 control (choose between immediate value added PC or PC+4)
    assign ZERO_AND_BRANCHFLAG = ZERO & BRANCH_FALG;

    //left shifting by 2 (as the jump instruction immediate offset comes in terms of instructions) is achived by wiring
    //sign is extended by concatenating the MSB 22 times
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
    
    always @ (READ_DATA,ALURESULT,LOAD_WORD_FLAG) begin//mux 5 (where alu out or memory out is choosen)
        case (LOAD_WORD_FLAG)
            0 : REG_FILE_DATA_IN <= ALURESULT;
            1 : REG_FILE_DATA_IN <= READ_DATA;//memory output
        endcase
    end

    always @ (posedge CLK) begin//synchronous reset of the pc
        if(RESET)
            PC <= #1 32'b0;
        if(!BUSYWAIT & !RESET)
            PC <= #1 PC_NEXT;
    end

endmodule


module control_unit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG,BRANCH_FALG,JUMP_FALG,WRITE,READ,LOAD_WORD_FLAG,BUSYWAIT);
    
    input [31:0] INSTRUCTION;
    input BUSYWAIT;
    output reg WRITEENABLE;
    output reg [2:0] ALUOP;
    output reg COMPLEMENT_FLAG;
    output reg IMMEDIATE_FALG;
    output reg BRANCH_FALG;
    output reg JUMP_FALG;
    output reg WRITE;
    output reg READ;
    output reg LOAD_WORD_FLAG;

    wire [7:0] opcode;
    assign opcode = INSTRUCTION[31:24];

    always @ (INSTRUCTION) begin
        READ = 0;
        WRITE = 0;
    end

    always @ (opcode,BUSYWAIT) begin//control unit decisions ; with simulated decoding delays
        case (opcode)
            8'b0000_0000 : begin//register is written into and an immediate value is chosen in a loadi instruction
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;//doesn't matter 0 or 1
                IMMEDIATE_FALG <=#1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;//loadi==>foward                  
            end
            8'b0000_0001 : begin// uncomplemented register file output two is fowarded to be written     
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;//mov==>foward 
            end
            8'b0000_0010 : begin//uncomplemented values are added             
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b001;//add==>add
            end
            8'b0000_0011 : begin//complemented values are added    
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b001;//sub==>add
            end
            8'b0000_0100 : begin//uncomplemented reg values are andded 
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b010;//and==>and  
            end
            8'b0000_0101 : begin//uncomplemented values are orred         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b011;//or==>or    
            end
            8'b0000_0110 : begin//jump instruction ; alu's behaviour doesn't matter
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 1;//jump is set to 1
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;    
            end
            8'b0000_0111 : begin//beq instruction ; alu performs an add operation with the complemented data2 value         
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 1;//branch flag is set to 1
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b010;//beq==>add
            end
            8'b0000_1000 : begin//lwd instruction ; alu performs a foward operation 
                WRITEENABLE <= #1 1;//write to reg file
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 1;//read memory
                LOAD_WORD_FLAG <=#1 1;
                ALUOP <= #1 3'b000;
            end
            8'b0000_1001 : begin//lwi instruction ; alu performs a foward operation       
                WRITEENABLE <= #1 1;//write to reg file
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 1;//read memory
                LOAD_WORD_FLAG <=#1 1;
                ALUOP <= #1 3'b000;
            end
            8'b0000_1010 : begin//swd instruction ; alu performs a foward operation         
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 1;//write to memory
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;
            end
            8'b0000_1011 : begin//swi instruction ; alu performs a foward operation 
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 1;//write to memory
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;
            end
            default : begin              
                WRITEENABLE <= #1 1'bz;
                COMPLEMENT_FLAG <= #1 1'bz;
                IMMEDIATE_FALG <= #1 1'bz;
                BRANCH_FALG <=#1 1'bz;
                JUMP_FALG <=#1 1'bz;
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