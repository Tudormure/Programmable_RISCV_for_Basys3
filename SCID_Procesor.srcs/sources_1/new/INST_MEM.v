`timescale 1ns/1ps

module INST_MEM(
    input clk,
    input we,
    input [31:0] pc_address,
    input [31:0] outside_address,
    input [31:0] write_data,
    output [31:0] instruction
);
    reg [31:0] ram [0:1023]; //4KB de memorie de instructiuni (1000 de instructiuni)
    
    integer i;
    initial begin
        //initializam cu 0 memoria
        for (i = 0; i < 1024; i = i + 1) begin
            ram[i] = 32'd0;
        end
        //instructiuni pentru incarcarea procesorului gata programat (optional)
         $readmemh("../../../../program.txt", ram);//cale relativa
    end
    
    always @(posedge clk) begin
        if (we == 1'b1) begin
            //pentru scrierea instructiunilor primite din Serial
            ram[outside_address >> 2] <= write_data;
        end  
    end
        
    assign instruction = (we == 1'b1) ? 32'b0 : ram[pc_address >> 2];

endmodule