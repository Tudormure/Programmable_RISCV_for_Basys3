`timescale 1ns/1ps

module ALU(
    input [31:0] imm,//valoare imediata(constanta)
    input alu_src,//daca e 0 foloseste rs2, altfel = 1 foloseste imm 
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [3: 0] alu_control,
    output reg [31:0] result,
    output zero
);

    //pentru instructiuni de tip branch, ifuri
    wire [31:0] temp;
    assign temp = (alu_src == 1'b1) ? imm : rs2_data;
    assign zero = (result == 32'd0);//pentru BEQ, daca rezultatul unei scaderi este 0 inseamna ca 2 numere sunt egale
    
    
    always @(*) begin
        case(alu_control)
            4'b0000: result = rs1_data & temp; //AND
            4'b0001: result = rs1_data | temp; //OR
            4'b0010: result = rs1_data + temp; //ADD
            4'b0110: result = rs1_data - temp; //SCADERE
            4'b0111: result = ($signed(rs1_data) < $signed(temp)) ? 32'd1 : 32'd0;
            //SLT compara -> daca a < b e 1 altfel 0
            4'b1000: result = rs1_data ^ temp; //XOR
            4'b0101: result = rs1_data << temp[4:0];
            //SLL shift left rs2_data[4:0] (sau imm) biti adica maxim 32 de biti
            4'b1101: result = rs1_data >> temp[4:0];
            //SRL shift right rs2_data[4:0] (sau imm) biti
            4'b1100: result = ~(rs1_data|temp); //NOR
            default: result = 32'd0;
         endcase
    end
            
            
            
            
            

endmodule