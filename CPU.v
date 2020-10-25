`include "REG_FILE.v"
`include "ALU.v"

module cpu(PC, INSTRUCTION, CLK, RESET)
    input CLK, RESET;
    output [31:0] PC;
    output [31:0] PC_NEXT;
    input [31:0] INSTRUCTION;
    reg WRITEENABLE;
    wire [2:0] ALUOP;
    reg COMPLEMENT_FLAG;
    reg IMMEDIATE_FALG;
    wire [2:0] WRITEREG;
    wire [7:0] REGOUT1;
    wire [7:0] REGOUT2;
    wire [7:0] COMPLEMENTED_OUT;
    wire [7:0] COMPLEMENT_MUX_OUT;
    wire [7:0] IMMEDIATE_MUX_OUT;
    wire [7:0] IMMEDIATE;
    wire [7:0] ALU_RESULT;
    wire [7:0] READREG1;
    wire [7:0] READREG2;
	
    control_unit ctrlUnit(CLK,INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG);
    pc_adder pcNext(PC,PC_NEXT);
    reg_file regFile(ALU_RESULT,REGOUT1,REGOUT2,WRITEREG,READREG1,READREG2, WRITEENABLE, CLK, RESET);
    alu ALU(REGOUT1,IMMEDIATE_MUX_OUT,ALU_RESULT,ALUOP);
    twosComplement complementor(REGOUT2,COMPLEMENTED_OUT);

    always @ (REGOUT2,COMPLEMENTED_OUT,COMPLEMENT_FLAG) begin
        case (COMPLEMENT_FLAG)
            0 : COMPLEMENT_MUX_OUT = REGOUT2;
            1 : COMPLEMENT_MUX_OUT = COMPLEMENTED_OUT;
        endcase
    end

    always @ (COMPLEMENT_MUX_OUT,IMMEDIATE_MUX_OUT,IMMEDIATE_FALG) begin
        case (IMMEDIATE_FALG)
            0 : IMMEDIATE_MUX_OUT = COMPLEMENT_MUX_OUT;
            1 : IMMEDIATE_MUX_OUT = IMMEDIATE;
        endcase
    end


endmodule

module control_unit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG)
    wire opcode[7:0];
    
    opcode = INSTRUCTION[7:0];

    always @ (INSTRUCTION) begin
        case (opcode)
            8'b0000_0000 : begin
                ALUOP = 3'b000;//loadi==>foward                  
                WRITEENABLE = 1;
                COMPLEMENT_FLAG =0;
                IMMEDIATE_FALG =1;
            end
            8'b0000_0001 : begin
                ALUOP = 3'b000;//mov==>foward                  
                WRITEENABLE = 1;
                COMPLEMENT_FLAG =0;
                IMMEDIATE_FALG =0;
            end
            8'b0000_0010 : begin
                ALUOP = 3'b001;//add==>add                  
                WRITEENABLE = 1;
                COMPLEMENT_FLAG =0;
                IMMEDIATE_FALG =0;
            end
            8'b0000_0011 : begin
                ALUOP = 3'b001;//sub==>add                  
                WRITEENABLE = 1;
                COMPLEMENT_FLAG =1;
                IMMEDIATE_FALG =0;
            end
            8'b0000_0100 : begin
                ALUOP = 3'b010;//and==>and                  
                WRITEENABLE = 1;
                COMPLEMENT_FLAG =0;
                IMMEDIATE_FALG =0;
            end
            8'b0000_0101 : begin
                ALUOP = 3'b011;//or==>or                  
                WRITEENABLE = 1;
                COMPLEMENT_FLAG =0;
                IMMEDIATE_FALG =0;
            end
            default : begin
                ALUOP = 3'b000;                  
                WRITEENABLE = 0;
                COMPLEMENT_FLAG =0;
                IMMEDIATE_FALG =0;
            end
        endcase 

           /* 8'b0000_0110 : ALUOP = 3'b001;//j==>add
            8'b0000_0111 : ALUOP = 3'b001;//sub==>add
            8'b0000_1000 : ALUOP = 3'b001;//sub==>add
            8'b0000_1001 : ALUOP = 3'b001;//sub==>add
            8'b0000_1010 : ALUOP = 3'b001;//sub==>add
            8'b0000_1011 : ALUOP = 3'b001;//sub==>add
        
            char *op_loadi 	= "00000000";
            char *op_mov 	= "00000001";
            char *op_add 	= "00000010";
            char *op_sub 	= "00000011";
            char *op_and 	= "00000100";
            char *op_or 	= "00000101";
            char *op_j		= "00000110";
            char *op_beq	= "00000111";
            char *op_lwd 	= "00001000";
            char *op_lwi 	= "00001001";
            char *op_swd 	= "00001010";
            char *op_swi 	= "00001011";
            */

        end
    end

endmodule

module twosComplement(REGOUT2,COMPLEMENTED_OUT)
    input reg signed [7:0] REGOUT2;
    output signed [7:0] COMPLEMENTED_OUT;

    assign #1 COMPLEMENTED_OUT = - REGOUT2;

endmodule

module pc_adder(PC,PC_NEXT)
    input [31:0] PC;
    output [31:0] PC_NEXT;

    assign #2 PC_NEXT = PC + 32'b0001;//MSBs are filled with 0s

endmodule
