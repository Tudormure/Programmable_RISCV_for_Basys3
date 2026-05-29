`timescale 1ns / 1ps

module REG_FILE(
    input clk,
    input we,
    input [4:0] rs1_addr,
    input [4:0] rs2_addr,
    input [4:0] rd_addr,
    input [31:0] write_data,
    output [31:0] rs1_data,
    output [31:0] rs2_data,
    input [4:0] debug_addr,     
    output [31:0] debug_data   
    
    );
    
    reg [31:0] registers [0:31];
    
    integer i;
    initial begin
        for (i=0;i<=31;i =  i +1) begin
            registers[i] = 32'd0;
        end
    end
        
    always @(posedge clk) begin
        
        if (we == 1'b1 && rd_addr != 5'd0) begin
            registers[rd_addr] <= write_data;
        end
    end
    //daca cere din adresa 0 ii dam val 0, altfel valoarea stocata
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0)? 32'd0:registers[rs2_addr];
    //pentru 7 seg display
    assign debug_data = (debug_addr == 5'b00000) ? 32'b0 : registers[debug_addr];
endmodule
