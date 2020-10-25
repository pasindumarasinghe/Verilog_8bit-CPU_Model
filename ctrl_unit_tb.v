`include "CPU.v"

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
    end

    initial begin
        RESET =1;#4 RESET =0;
        #8
        $monitor($time,"INSTRUCTION=%b ,WRITEENABLE=%d ,ALUOP=%d ,COMPLEMENT_FLAG=%d,IMMEDIATE_FALG=%d\n",INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG);
        #200 $finish;
    end

endmodule
