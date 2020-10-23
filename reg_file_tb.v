// Computer Architecture (CO224) - Lab 05
// Design: Register File Testbench of Simple Processor
// Author: Kisaru Liyanage
// Date	: 21-October-2020

module reg_file_tb;
    
    reg [7:0] WRITEDATA;
    reg [2:0] WRITEREG, READREG1, READREG2;
    reg CLK, RESET, WRITEENABLE; 
    wire [7:0] REGOUT1, REGOUT2;
    
    reg_file myregfile(WRITEDATA, REGOUT1, REGOUT2, WRITEREG, READREG1, READREG2, WRITEENABLE, CLK, RESET);
       
    initial
    begin
        CLK = 1'b1;
        
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("reg_file_wavedata.vcd");
		$dumpvars(0, reg_file_tb);
        
        // assign values with time to input signals to see output 
        RESET = 1'b0;
        WRITEENABLE = 1'b0;
        
        #5
        RESET = 1'b1;
        READREG1 = 3'd0;
        READREG2 = 3'd4;
        
        #7
        RESET = 1'b0;
        
        #3
        WRITEREG = 3'd2;
        WRITEDATA = 8'd95;
        WRITEENABLE = 1'b1;
        
        #9
        WRITEENABLE = 1'b0;
        
        #1
        READREG1 = 3'd2;
        
        #9
        WRITEREG = 3'd1;
        WRITEDATA = 8'd28;
        WRITEENABLE = 1'b1;
        READREG1 = 3'd1;
        
        #10
        WRITEENABLE = 1'b0;
        
        #10
        WRITEREG = 3'd4;
        WRITEDATA = 8'd6;
        WRITEENABLE = 1'b1;
        
        #10
        WRITEDATA = 8'd15;
        WRITEENABLE = 1'b1;
        
        #10
        WRITEENABLE = 1'b0;
        
        #6
        WRITEREG = 3'd1;
        WRITEDATA = 8'd50;
        WRITEENABLE = 1'b1;
        
        #5
        WRITEENABLE = 1'b0;
        
        #10
        $finish;
    end
    
    // clock signal generation
    always
        #5 CLK = ~CLK;
        

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

    integer i ;

    assign #2 OUT1 = REG_FILE[OUT1ADDRESS] ;//continuously assigning the values in the regisers to output ports with a delay

    assign#2 OUT2 = REG_FILE[OUT2ADDRESS] ;

    always @ (posedge CLK) begin//at the positive edge of the clock signal
        if (RESET) begin//if reset signal is enabled, assign registers to  all zeros
            for (i=0;i<8;i++) 
                REG_FILE[i] <= #1 8'b0000_0000;
        end else if (WRITE) begin//if the reset is not enabled and the write is enabled write IN value to the relevent register
            REG_FILE[INADDRESS] <= IN;
        end
    end

endmodule