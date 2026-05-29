`timescale 1ns / 1ps

module basys3_top(
    input clk,            //100meg clk intern
    input btnC,           //btn mijloc
    input [15:0] sw,      //sw [4:0] registrii, sw[15] load enable/disable
    input RsRx,           // Pinul fizic de recepție UART (RX) de pe placă
    output [6:0] seg,     // 7seg
    output [3:0] an,      // anozi
    output led            // clk
);

    wire [31:0] cpu_debug_data;
    wire cpu_rst;
   
    assign cpu_rst = btnC | sw[15]; //nu se ruleaza cod

    // loader
    wire rx_ready_wire;
    wire [7:0] rx_data_wire;
    wire [31:0] l_addr, l_data;
    wire l_we;
    uart_rx receiver (
        .clk(clk),
        .rx(RsRx),
        .rx_data(rx_data_wire),
        .rx_ready(rx_ready_wire)
    );

    program_loader loader (
        .clk(clk),
        .rx_ready(rx_ready_wire),
        .rx_data(rx_data_wire),
        .sw_prog(sw[15]),
        .loader_addr(l_addr),
        .loader_data(l_data),
        .loader_we(l_we)
    );

    FINAL_BUILD_UP cpu (
        .clk(clk),
        .rst(cpu_rst),
        .we(l_we),              //loader write enable
        .addr_ext(l_addr),      //adresa loader
        .data_ext(l_data),      //instructiune loader
        .led_out(led),        
        
        .sw_reg_select(sw[4:0]),
        .lcd_val_out(cpu_debug_data)
    );
    sev_seg_driver display (
        .clk(clk),
        .data_in(cpu_debug_data[15:0]),
        .an(an),
        .seg(seg)
    );
endmodule