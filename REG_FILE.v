module testbed;//for testing the alu
    reg [7:0] IN;
    reg [2:0] INADDRESS,OUT1ADDRESS,OUT2ADDRESS;//creating registers and wires
    reg WRITE, CLK, RESET;
    wire [7:0] OUT1,OUT2;

    initial begin
        $monitor($time," OUT1 : %b OUT2 : %b",OUT1,OUT2);//monitering the changes in results
        $dumpfile("regfile_wavedata.vcd");//wavedata dumpfile to be examined with GTKwave
        $dumpvars(0,testbed);//dumpng all the variables in the testbed 
    end

    reg_file myreg(IN,OUT1,OUT2,INADDRESS,OUT1ADDRESS,OUT2ADDRESS, WRITE, CLK, RESET);//instanciating the register file module

    initial begin//creating a clock signal that flips every 10 time units forever 
        CLK = 1'b0;
        forever #10 CLK = ~CLK;	
    end

    initial begin 
        #50
        OUT1ADDRESS  = 3'b000;
        OUT2ADDRESS = 3'b001;
    end
    
    initial begin 
        #5
        RESET = 1;
        WRITE = 0;
    end
    
    initial begin 
        #15
        RESET =0;
        WRITE = 1;
        IN = 8'b0001_0001;
        INADDRESS  = 3'b000;
    end
    
    initial begin 
        #25
        IN = 8'b1000_1000;
        INADDRESS  = 3'b001;
    end
    
    initial begin 
        #35
        WRITE = 0;
        IN = 8'b0001_0001;
        INADDRESS  = 3'b000;

    end
    
    initial begin//finishing the simulation
        #100
        $finish;
    end

endmodule

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

    integer index_in;//creating int variables to index the reg_file
    integer index_out1;
    integer index_out2;
    integer i;

    always @ (INADDRESS,OUT1ADDRESS,OUT2ADDRESS) begin
        index_in = INADDRESS;
        index_out1 = OUT1ADDRESS;
        index_out2 = OUT2ADDRESS;
    end

    assign #2 OUT1 = REG_FILE[index_out1] ;//continuously assigning the values in the regisers to output ports with a delay

    assign #2 OUT2 = REG_FILE[index_out2] ;

    always @ (posedge CLK) begin//at the positive edge of the clock signal
        if (RESET) begin//if reset signal is enabled, assign registers to  all zeros
            for (i=0;i<8;i++) 
                REG_FILE[i] <= 8'b0000_0000;
        end else if (WRITE) begin//if the reset is not enabled and the write is enabled write IN value to the relevent register
            REG_FILE[index_in] <= IN;
        end
    end

endmodule
