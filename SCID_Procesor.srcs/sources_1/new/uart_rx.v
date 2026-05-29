`timescale 1ns / 1ps

module uart_rx(
    input clk,
    input rx,
    output reg [7:0] rx_data,
    output reg rx_ready
);
    parameter CLK_PER_BIT = 10416; //9600 baud
    //100mhz / 9600 baud = 10416 clks pt un bit
    
    reg [1:0] rx_state = 0;
    reg [13:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] rx_shift_reg = 0;
    
    always @(posedge clk) begin
        rx_ready <= 1'b0;
        case (rx_state)
            0: begin
                if (rx == 1'b0) begin
                    if (clk_count == CLK_PER_BIT/2 - 1) begin
                        //numar cate clockuri trec pt un bit , astfel incat sa citim la jumatatea bitului
                        clk_count <= 0;
                        rx_state <= 1;
                    end else clk_count <= clk_count + 1;
                end else clk_count <= 0;
            end
            1: begin
                if (clk_count == CLK_PER_BIT - 1) begin//deja avem delayul de jumatatea bitului de sus
                    clk_count <= 0;
                    rx_shift_reg[bit_index] <= rx;
                    if (bit_index == 7) begin
                        bit_index <= 0;
                        rx_state <= 2;
                    end else bit_index <= bit_index + 1;
                end else clk_count <= clk_count + 1;
            end
            2: begin
            //asteptam bitul de final, al 10 lea bit
                if (clk_count == CLK_PER_BIT - 1) begin
                    clk_count <= 0;
                    if(rx == 1'b1) begin//if optional
                        rx_data <= rx_shift_reg;
                        rx_ready <= 1'b1;
                    end
                    rx_state <= 0;
                end else clk_count <= clk_count + 1;
            end
            
            default: rx_state <= 0;
        endcase
    end
endmodule