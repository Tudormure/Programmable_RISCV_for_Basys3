`timescale 1ns/ 1ps

module PC(
    input clk,
    input rst,
    input pc_src,//daca da jump undeva
    input [31:0] branch_target,//cat da jump
    output [31:0] pc_out
);
    
    wire[31:0] pc_next_wire;
    wire[31:0] pc_plus_4;
    wire[31:0] pc_current_wire;
    //daca pc_src e 1 sarim la branc_target, daca e 0 mergem la adresa urmatoarei instructiuni
    assign pc_next_wire = (pc_src == 1'b1) ? branch_target : pc_plus_4;
    
    program_counter pc_inst(
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next_wire),
        .pc_out(pc_current_wire)
    );
    pc_increment adder_inst(
        .in(pc_current_wire),
        .res(pc_plus_4)
    );
    assign pc_out = pc_current_wire;

endmodule

