module control_unit(INSTRUCTION,WRITEENABLE,ALUOP,COMPLEMENT_FLAG,IMMEDIATE_FALG,BRANCH_FALG,JUMP_FALG,WRITE,READ,LOAD_WORD_FLAG,BUSYWAIT);
    
    input [31:0] INSTRUCTION;
    input BUSYWAIT;
    output reg WRITEENABLE;
    output reg [2:0] ALUOP;
    output reg COMPLEMENT_FLAG;
    output reg IMMEDIATE_FALG;
    output reg BRANCH_FALG;
    output reg JUMP_FALG;
    output reg WRITE;
    output reg READ;
    output reg LOAD_WORD_FLAG;

    wire [7:0] opcode;
    assign opcode = INSTRUCTION[31:24];

    always @ (INSTRUCTION) begin
        READ = 0;
        WRITE = 0;
    end

    always @ (opcode,BUSYWAIT) begin//control unit decisions ; with simulated decoding delays
        case (opcode)
            8'b0000_0000 : begin//register is written into and an immediate value is chosen in a loadi instruction
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;//doesn't matter 0 or 1
                IMMEDIATE_FALG <=#1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;//loadi==>foward                  
            end
            8'b0000_0001 : begin// uncomplemented register file output two is fowarded to be written     
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;//mov==>foward 
            end
            8'b0000_0010 : begin//uncomplemented values are added             
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b001;//add==>add
            end
            8'b0000_0011 : begin//complemented values are added    
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b001;//sub==>add
            end
            8'b0000_0100 : begin//uncomplemented reg values are andded 
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b010;//and==>and  
            end
            8'b0000_0101 : begin//uncomplemented values are orred         
                WRITEENABLE <= #1 1;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b011;//or==>or    
            end
            8'b0000_0110 : begin//jump instruction ; alu's behaviour doesn't matter
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 1;//jump is set to 1
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;    
            end
            8'b0000_0111 : begin//beq instruction ; alu performs an add operation with the complemented data2 value         
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 1;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 1;//branch flag is set to 1
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b010;//beq==>add
            end
            8'b0000_1000 : begin//lwd instruction ; alu performs a foward operation 
                WRITEENABLE <= #1 1;//write to reg file
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 1;//read memory
                LOAD_WORD_FLAG <=#1 1;
                ALUOP <= #1 3'b000;
            end
            8'b0000_1001 : begin//lwi instruction ; alu performs a foward operation       
                WRITEENABLE <= #1 1;//write to reg file
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 0;
                READ <=#1 1;//read memory
                LOAD_WORD_FLAG <=#1 1;
                ALUOP <= #1 3'b000;
            end
            8'b0000_1010 : begin//swd instruction ; alu performs a foward operation         
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 0;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 1;//write to memory
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;
            end
            8'b0000_1011 : begin//swi instruction ; alu performs a foward operation 
                WRITEENABLE <= #1 0;
                COMPLEMENT_FLAG <= #1 0;
                IMMEDIATE_FALG <= #1 1;
                BRANCH_FALG <=#1 0;
                JUMP_FALG <=#1 0;
                WRITE <=#1 1;//write to memory
                READ <=#1 0;
                LOAD_WORD_FLAG <=#1 0;
                ALUOP <= #1 3'b000;
            end
            default : begin              
                WRITEENABLE <= #1 1'bz;
                COMPLEMENT_FLAG <= #1 1'bz;
                IMMEDIATE_FALG <= #1 1'bz;
                BRANCH_FALG <=#1 1'bz;
                JUMP_FALG <=#1 1'bz;
                ALUOP <= #1 3'bzzz;    
            end
        endcase          
            
    end

endmodule