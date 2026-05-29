`timescale 1ns / 1ps

module program_counter(
    input clk,
    input rst,
    input [31:0] pc_next,    
    output reg [31:0] pc_out
);
always @(posedge clk or posedge rst) begin
    if (rst) 
        pc_out <= 32'd0;
    else 
        pc_out <= pc_next;  
end
endmodule

module pc_increment(
    input [31:0] in,
    output [31:0] res
);
assign res = in + 32'b100;
endmodule
