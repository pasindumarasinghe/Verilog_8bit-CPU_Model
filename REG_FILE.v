/*
module testbed;//for testing the reg_file
    reg [7:0] IN;
    reg [2:0] INADDRESS,OUT1ADDRESS,OUT2ADDRESS;//creating registers and wires
    reg WRITE, CLK, RESET;
    wire [7:0] OUT1,OUT2;

    initial begin
        $monitor($time," OUT1 : %b OUT2 : %b",OUT1,OUT2);//monitering the changes in results
        $dumpfile("REG_REG_FILE_wavedata.vcd");//wavedata dumpfile to be examined with GTKwave
        $dumpvars(0,testbed);//dumpng all the variables in the testbed 
    end

    reg_file myreg(IN,OUT1,OUT2,INADDRESS,OUT1ADDRESS,OUT2ADDRESS, WRITE, CLK, RESET);//instanciating the register file module


    initial begin//creating a clock signal that flips every 10 time units forever 
        CLK = 1'b0;
        forever #10 CLK = ~CLK;	
    end

    
    initial begin

		Testing the RESET
		-----------------
		The clock goes up at t = 10. Therefore, the registers should be reset t = 10.
		Since reading has a delay of 2 time units, OUT1 and OUT2 should be 0 at t=12.
	
        #5
        RESET = 1;
        WRITE = 0;
        OUT1ADDRESS = 3'b000;
        OUT2ADDRESS = 3'b001; 
        
		
    end

    The register starts to write 8'b00011111 in the register 3'b010 at t=30. Since writing has a delay of 1 time units,
    the value should be written into the register at t=31.When the value of the register is read the OUT1 should be 
    8'b00010001 at t = 33. Since the OUT2ADDRESS did't change the value should be 8'b00000000.

    initial begin 
        #25
        RESET =0;
        WRITE = 1;
        IN = 8'b0001_1111;
        INADDRESS  = 3'b010;
        OUT1ADDRESS = 3'b010;
    end
 
     
    Making sure the register doesn't work at a negative edge of the clock.
    There is a negative edge of the clock at t=40. Even though the WRITE is enabled, the writing process does not take placa.
    So at t = 39+2 = 41 , OUT1 and OUT2 should be 8b'00000000.
    
    
    initial begin 
        #39
        WRITE = 1;
        IN = 8'b0000_1111;
        INADDRESS  = 3'b011;
        OUT1ADDRESS = 3'b011;
    end
    
    
    //Writing to a register and Reading it (using the OUT2)

    initial begin 
        #45
        WRITE = 1;
        IN = 8'b0101_0101;
        INADDRESS  = 3'b100;
		OUT2ADDRESS = 3'b100;
    end
 
	
    initial begin
        #70
        INADDRESS = 3'b010;
        IN = 8'b1111_1111;
        OUT2ADDRESS  = 3'b010;
         
    end
    
  
    initial begin//finishing the simulation
        #100
        $finish;
    end

endmodule
*/

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

    assign #2 OUT2 = REG_FILE[OUT2ADDRESS] ;

    always @ (posedge CLK) begin//at the positive edge of the clock signal
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