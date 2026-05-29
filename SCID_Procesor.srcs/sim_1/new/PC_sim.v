`timescale 1ns/1ps

module PC_sim();
    reg clk;
    reg rst;
    wire [31:0] pc_out;
    
    PC UUT(
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        rst = 1;
        
        #20
        
        rst = 0;
        
        #1000
        
        $finish;
    end
    
    
endmodule