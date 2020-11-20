module reg_file(IN,OUT1,OUT2,INADDRESS,OUT1ADDRESS,OUT2ADDRESS, WRITE, CLK, RESET,BUSYWAIT);
    input [7:0] IN;
    input BUSYWAIT;
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

    assign #2 OUT2 = REG_FILE[OUT2ADDRESS] ;

    always @ (posedge CLK & !BUSYWAIT) begin//at the positive edge of the clock signal
        if (RESET) begin//if reset signal is enabled, assign registers to  all zeros
            for (i=0;i<8;i++) 
                REG_FILE[i] <= #1 8'b0000_0000;
        end else if (WRITE) begin//if the reset is not enabled and the write is enabled write IN value to the relevent register
            #1 REG_FILE[INADDRESS] <=  IN;
        end
    end
      /* START DEBUGGING CODE (Not required in the usual implementation */
    initial
    begin
    // monitor changes in reg file content and print (used to check whether the CPU is running properly)
    $display("\n\t\t\t=================================================");
    $display("\t\t\t Change of Register Content Starting from Time #5");
    $display("\t\t\t==================================================\n");
    $display("\t\ttime\treg0\treg1\treg2\treg3\treg4\treg5\treg6\ttreg7");
    $display("\t\t-----------------------------------------------------");
    $monitor($time, "\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d",REG_FILE[0],REG_FILE[1],REG_FILE[2],REG_FILE[3],REG_FILE[4],REG_FILE[5],REG_FILE[6],REG_FILE[7]);
    end
    /* END DEBUGGING CODE */

endmodule