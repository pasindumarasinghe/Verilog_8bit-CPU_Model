`include "REG_FILE.v"
`include "ALU.v"

module cpu(PC, INSTRUCTION, CLK, RESET);

    input CLK,RESET;
    output reg [31:0] PC;//need to store the value of pc to be output 
    input [31:0] INSTRUCTION; 

    wire WRITEENABLE;
    wire [31:0] PC_NEXT; //this wire holds the adder's output until the next posedge 
    wire [2:0] ALUOP;
    wire COMPLEMENT_FLAG;//control signal for the mux 1 (where complemented or original value is choosen)
    wire IMMEDIATE_FALG;//control signal for the mux 2 (where immediate value or mux 1's out is choosen)
    wire [7:0] REGOUT1;//registerfile out 1
    wire [7:0] REGOUT2;//registerfile out 2
    wire [7:0] COMPLEMENTED_OUT;//output from the 2's complementor
    reg [7:0] COMPLEMENT_MUX_OUT;//output from the mux 1 (complement)
    reg [7:0] IMMEDIATE_MUX_OUT;//output from the mux 2 (immediate)
    wire [7:0] IMMEDIATE;//immediate value from the control unit 
    wire [7:0] ALU_RESULT;

    //register file inputs
    wire [2:0] READREG1;
    wire [2:0] READREG2;
    wire [2:0] WRITEREG;

    //setting the wires for immediate value and reg_file inputs with relevent bits of the instruction
    assign WRITEREG = INSTRUCTION[23:16];
    assign READREG1 = INSTRUCTION[15:8];
    assign READREG2 = INSTRUCTION[7:0];
    assign IMMEDIATE = INSTRUCTION[7:0];
	
    //instantiating the modules control unit, pc adder, reg file, alu and the complementor
    control_unit ctrlUnit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG);
    pc_adder pcNext(PC,PC_NEXT);
    reg_file regFile(ALU_RESULT,REGOUT1,REGOUT2,WRITEREG,READREG1,READREG2, WRITEENABLE, CLK, RESET);
    alu ALU(REGOUT1,IMMEDIATE_MUX_OUT,ALU_RESULT,ALUOP);
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

    always @ (posedge CLK) begin//synchronous reset of the pc
        case(RESET)
            0 : PC <= #1 PC_NEXT;
            1 : PC <= #1 32'b0;
        endcase
    end

endmodule


module control_unit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG);
    
    input [31:0] INSTRUCTION;
    output reg WRITEENABLE;
    output reg [2:0] ALUOP;
    output reg COMPLEMENT_FLAG;
    output reg IMMEDIATE_FALG;

    wire [7:0] opcode;
    assign opcode = INSTRUCTION[31:24];//decoding delay

    always @ (opcode) begin//control unit decisions
        case (opcode)
            8'b0000_0000 : begin//register is written into and an immediate value is chosen in a loadi instruction
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;//doesn't matter 0 or 1
                IMMEDIATE_FALG <=#1 1;
                ALUOP <= #1 3'b000;//loadi==>foward                  
            end
            8'b0000_0001 : begin// uncomplemented register file output two is fowarded to be written     
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b000;//mov==>foward 
            end
            8'b0000_0010 : begin//uncomplemented values are added             
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b001;//add==>add
            end
            8'b0000_0011 : begin//complemented values are added    
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b001;//sub==>add
            end
            8'b0000_0100 : begin//uncomplemented reg value is andded 
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b010;//and==>and  
            end
            8'b0000_0101 : begin//uncomplemented values are orred         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b011;//or==>or    
            end
            default : begin              
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                ALUOP <= #1 3'b000;    
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
