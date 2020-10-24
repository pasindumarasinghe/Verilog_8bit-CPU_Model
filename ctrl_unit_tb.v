module tb 
    input reg CLK, RESET;
    //output [31:0] PC;
    input [31:0] INSTRUCTION;
    reg WRITEENABLE;
    wire [2:0] ALUOP;
    reg COMPLEMENT_FLAG;
    reg IMMEDIATE_FALG;
	
    control_unit myctrlunit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG);

    always begin
        CLK = 1; 
        $monitor($time,"INSTRUCTION=%b ,WRITEENABLE=%d ,ALUOP=%d ,COMPLEMENT_FLAG=%d,IMMEDIATE_FALG=%d",INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG);
        #4 CLK = ~ CLK;
        #200 $finish;
    end

    initial begin
        RESET =1;#4 RESET =0;
        #8
        $monitor($time,"INSTRUCTION=%b ,WRITEENABLE=%d ,ALUOP=%d ,COMPLEMENT_FLAG=%d,IMMEDIATE_FALG=%d\n",INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG);

    end

begin
    
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
            8'b0000_0101 : ALUOP = 3'b011;//or==>or
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