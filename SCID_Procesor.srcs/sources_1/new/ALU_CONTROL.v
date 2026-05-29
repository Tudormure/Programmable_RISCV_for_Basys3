`timescale 1ns / 1ps

module ALU_CONTROL(
    input [1:0] ALUOp,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [3:0] alu_control
);

    always @(*) begin
        case(ALUOp)
            2'b00: alu_control = 4'b0010;//cod pt add daca e load/store, calculam adrese
            2'b01: alu_control = 4'b0110;//cod pt sub daca e tip branch
            
            2'b10: begin
                case(funct3)
                    3'b000: begin
                        if (funct7[5] == 1'b1) 
                            alu_control = 4'b0110;//SUB
                        else 
                            alu_control = 4'b0010;//ADD
                    end
                    3'b111: alu_control = 4'b0000;//AND
                    3'b110: alu_control = 4'b0001;//OR
                    3'b100: alu_control = 4'b1000;//XOR
                    3'b010: alu_control = 4'b0111;//SLT
                    3'b001: alu_control = 4'b0101;//SLL
                    3'b101: alu_control = 4'b1101;//SRL
                    default: alu_control = 4'b0000;
                endcase
               end
               default: alu_control = 4'b0000;
        endcase     
    end
endmodule
