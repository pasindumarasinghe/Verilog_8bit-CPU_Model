module reg_file(IN,OUT1,OUT2,INADDRESS,OUT1ADDRESS,OUT2ADDRESS, WRITE, CLK, RESET);
    input [7:0] IN;
    output [7:0] OUT1;
    output [7:0] OUT2;
    input [2:0] INADDRESS;//defining inputs and outputs
    input WRITE;
    input CLK;
    input RESET;
    input [2:0] OUT1ADDRESS;
    input [2:0] OUT2ADDRESS;

    reg [7:0] REG_FILE [7:0] ;//creating the registers

    integer i ;

    assign #2 OUT1 = REG_FILE[OUT1ADDRESS] ;//continuously assigning the values in the regisers to output ports with a delay

    assign#2 OUT2 = REG_FILE[OUT2ADDRESS] ;

    always @ (posedge CLK) begin//at the positive edge of the clock signal
        if (RESET) begin//if reset signal is enabled, assign registers to  all zeros
            for (i=0;i<8;i++) 
                REG_FILE[i] <= #2 8'b0000_0000;
        end else if (WRITE) begin//if the reset is not enabled and the write is enabled write IN value to the relevent register
            #1 REG_FILE[INADDRESS] <=  IN;
        end
    end

endmodule
