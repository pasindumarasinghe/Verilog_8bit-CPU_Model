module testbed;

    reg [7:0] DATA1,DATA2;
    reg [2:0] SELECT;
    wire [7:0] RESULT;

    initial begin
        $monitor($time," result : %b",RESULT);
        $dumpfile("alu_wavedata.vcd");
        $dumpvars(0,testbed);
    end

    alu myALU(DATA1,DATA2,RESULT,SELECT);

    initial begin
        DATA1 = 8'b10000001;
        DATA2 = 8'b01001110;
    end

    initial begin
        #10
        SELECT = 3'b001;
        DATA1 = 8'b00000001;
        DATA2 = 8'b00000011;
    end

    initial begin
        #15
        SELECT = 3'b010;
        DATA1 = 8'b11010101;
        DATA2 = 8'b11101010;
    end

    initial begin
        #20
        SELECT = 3'b011;
        DATA1 = 8'b00000001;
        DATA2 = 8'b00000010;
    end
    
    initial begin
        #25
        SELECT = 3'b000;
        DATA1 = 8'b10000001;
        DATA2 = 8'b01111110;
    end

    initial begin
        #700 $finish;
    end

endmodule

module alu(DATA1,DATA2,RESULT,SELECT);

    input  [7:0] DATA1 ;
    input  [7:0] DATA2 ;
    input  [2:0] SELECT ;
    output reg [7:0] RESULT;

    wire [7:0] result1,result2,result3,result4;

    FORWARD Forward(DATA2,result1);
    ADD Add(DATA1,DATA2,result2);
    AND And(DATA1,DATA2,result3) ;
    OR Or(DATA1,DATA2,result4) ;

   always @ (DATA1,DATA2,SELECT) begin

    case (SELECT)

    3'b000 : RESULT <= result1;
    3'b001 : RESULT <= result2;
    3'b010 : RESULT <= result3;
    3'b011 : RESULT <= result4;
    default : RESULT <=result1;
    
    endcase

    end

endmodule
    
module FORWARD(DATA2,RESULT);

    input [7:0] DATA2 ;
    output [7:0] RESULT;
    assign #1 RESULT = DATA2;

endmodule

module ADD(DATA1,DATA2,RESULT);

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #2 RESULT = DATA1 + DATA2;

endmodule

module AND(DATA1,DATA2,RESULT) ;

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #1 RESULT = DATA1 & DATA2;

endmodule

module OR(DATA1,DATA2,RESULT) ;

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #1 RESULT = DATA1 | DATA2;

endmodule
