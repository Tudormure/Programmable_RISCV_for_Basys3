`timescale 1ns / 1ps

module program_loader(
    input clk,
    input rx_ready,
    input [7:0] rx_data,
    input sw_prog,   
    output reg [31:0] loader_addr,
    output reg [31:0] loader_data,
    output reg loader_we
);
    reg [1:0] byte_count = 0;
    reg [31:0] inst_buffer = 0;

    always @(posedge clk) begin
        loader_we <= 1'b0;
        
        if (!sw_prog) begin
            byte_count <= 0;
            loader_addr <= 32'b0;
        end else if (rx_ready) begin
            //little endian - de la lsb la msb
            case (byte_count)
                2'b00: begin inst_buffer[7:0]   <= rx_data; byte_count <= 1; end
                2'b01: begin inst_buffer[15:8]  <= rx_data; byte_count <= 2; end
                2'b10: begin inst_buffer[23:16] <= rx_data; byte_count <= 3; end
                2'b11: begin 
                    loader_data <= {rx_data, inst_buffer[23:0]};
                    loader_we <= 1'b1;
                    byte_count <= 0;
                    loader_addr <= loader_addr + 4; 
                end
            endcase
        end
    end
endmodule