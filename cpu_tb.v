// Computer Architecture (CO224) - Lab 05
// Design: Testbench of Integrated CPU of Simple Processor
// Author: Kisaru Liyanage
//Group : 12

`include "CPU.v"
`include "dmem.v"

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
    wire READ;
    wire WRITE;
    wire [7:0]ADDRESS;
    wire [7:0]WRITE_DATA;
    wire[7:0]READ_DATA;
    wire BUSYWAIT;
    reg [7:0] instr_mem[0:1023];//instruction memory array
    data_memory dmem(CLK,RESET,READ,WRITE,ADDRESS,WRITE_DATA,READ_DATA,BUSYWAIT);

    //taking 4 contiguous memory locations to create an instruction
    assign #2 INSTRUCTION = {instr_mem[PC+32'b0011],instr_mem[PC+32'b0010],instr_mem[PC+32'b0001],instr_mem[PC]};
    
    /* 
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
    
    // TODO: Initialize an array of registers (8x1024) named 'instr_mem' to be used as instruction memory
    
    // TODO: Create combinational logic to support CPU instruction fetching, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
    
    initial
    begin
        // Initialize instruction memory with the set of instructions you need execute on CPU
        
        // METHOD 1: manually loading instructions to instr_mem
        /*
        {instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]} = 32'b00000000000001000000000000000101;
        {instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]} = 32'b00000000000000100000000000001001;
        {instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]} = 32'b00000010000001100000010000000010;
        */
        // METHOD 2: loading instr_mem content from instr_mem.mem file
        $readmemb("instr_mem.mem", instr_mem);

    end

    /* 
    -----
     CPU
    -----
    */
    cpu mycpu(PC, INSTRUCTION, CLK, RESET,READ,WRITE,ADDRESS,WRITE_DATA,READ_DATA,BUSYWAIT);

    initial
    begin
    
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
        
        CLK = 1'b0;

        //creating a reset pulse of 5 time units
        RESET = 1'b1;
        #5
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        
        // finish simulation after some time
        #500
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        

endmodule