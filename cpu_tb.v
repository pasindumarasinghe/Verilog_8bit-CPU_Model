// Computer Architecture (CO224) - Lab 05
// Design: Testbench of Integrated CPU of Simple Processor
// Author: Kisaru Liyanage
//Group : 12

`include "CPU.v"

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
    
    /* 
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
    
    // TODO: Initialize an array of registers (8x1024) named 'instr_mem' to be used as instruction memory
    
    reg [7:0] instr_mem[0:1023];
    
    // TODO: Create combinational logic to support CPU instruction fetching, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
    assign #2 INSTRUCTION[7:0] = instr_mem[PC];
    assign #2 INSTRUCTION[15:8] = instr_mem[PC+1];
    assign #2 INSTRUCTION[23:16] = instr_mem[PC+2];
    assign #2 INSTRUCTION[31:24] = instr_mem[PC+3];
    
    initial
    begin
        //loading instr_mem content from instr_mem.mem file
        $readmemb("instr_mem.mem", instr_mem);
    end
    
    /* 
    -----
     CPU
    -----
    */
    cpu mycpu(PC, INSTRUCTION, CLK, RESET);

    initial
    begin
    
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        #1
        RESET = 1'b1;
        
        #5
        RESET = 1'b0; 
        // finish simulation after some time
        #500
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
endmodule
