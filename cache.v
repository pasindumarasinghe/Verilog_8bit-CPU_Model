module cache(
	clock,
    reset,
    read,
    write,
    address,
    writedata,
    readdata,
    busywait
);

input				clock;
input           	reset;
input           	read;
input           	write;
input[7:0]      	address;
input[31:0]     	writedata;
output reg [31:0]	readdata;
output reg      	busywait;

wire tag;
wire index;
wire offset;

assign tag = address[7:5];
assign index = address[4:2];
assign offset = address[1:0];

endmodule