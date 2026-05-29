`timescale 1ns / 1ps
module CONTROL_UNIT(
        input [6:0] opcode,
        output reg reg_write,
        output reg alu_src,
        output reg [1:0] alu_op,
        output reg mem_write,
        output reg mem_read,
        output reg mem_to_reg);
        
        
always @(*) begin
    reg_write   = 1'b0;
        alu_src     = 1'b0;
        alu_op      = 2'b00;
        mem_write   = 1'b0;
        mem_read    = 1'b0;
        mem_to_reg  = 1'b0;
    case(opcode)
            //r-type
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end
            //i-type ADDI,ANDI
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;//folosim constante
                alu_op    = 2'b00;
            end
            //load word
            7'b0000011: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = 2'b00; //ADD pt calcul adresa
                mem_read   = 1'b1;
                mem_to_reg = 1'b1; //rezultatul vine din memorie nu din alu
            end

            //store word
            7'b0100011: begin
                reg_write = 1'b0;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
                mem_write = 1'b1;
            end
                7'b1100011: begin //beq branch if equal
                alu_src    = 1'b0;  //sa foloseasca ce este in rs2
                mem_to_reg = 1'b0;  //nu conteaza
                reg_write  = 1'b0;  //nu scriem in registru cand sarim
                mem_read   = 1'b0;  //nu citim  din memorie cand sarim
                mem_write  = 1'b0;  //nu scriem in memorie cand sarim
                alu_op     = 2'b01; // CRITIC: 01 ca sa ii spuna ALU_CONTROL-ului sa faca SUB
            end
            
            default: ;
        endcase
    
    
end
endmodule
