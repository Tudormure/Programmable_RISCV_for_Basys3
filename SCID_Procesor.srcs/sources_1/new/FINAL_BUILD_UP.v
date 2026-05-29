`timescale 1ns / 1ps

module FINAL_BUILD_UP(
    input clk,
    input rst,
    input we, // pentru load
    input [31:0] addr_ext,
    input [31:0] data_ext,
    output wire led_out,
    input [4:0] sw_reg_select,
    output wire [31:0] lcd_val_out
);
    
    wire [31:0] pc_current_wire;
    wire [31:0] inst_wire;
    //decod----------------------------------------------
    wire [6:0] opcode_wire;
    wire [4:0] rd_wire;
    wire [2:0] funct3_wire;
    wire [4:0] rs1_wire;
    wire [4:0] rs2_wire;
    wire [6:0] funct7_wire;
    wire [11:0]imm_12_wire;
    //control---------------------------------------------
    wire reg_write_wire, alu_src_wire;
    wire [1:0] alu_op_wire;
    wire mem_write_wire, mem_read_wire, mem_to_reg_wire;
    //date-------------------------------------------------
    wire [31:0] rs1_data_wire, rs2_data_wire;
    wire [31:0] alu_result_wire;
    wire [3:0] alu_control_signal;
    wire zero_flag_wire;
    
    //wire nou pentru a extrage datele din REG_FILE
    wire [31:0] debug_reg_data_wire;
    
    //pentru sarituri---------------------------------------
    wire [31:0] imm_32_ext_wire = {{20{imm_12_wire[11]}}, imm_12_wire};
    //se copiaza de 20 de ori bitul de semn ca sa isi pastreze semnul si sa fie pe 32 de biti in loc de 12
    
    wire [12:0] imm_b_type = {inst_wire[31], inst_wire[7], inst_wire[30:25], inst_wire[11:8], 1'b0};
    
    
    wire [31:0] imm_32_branch = {{19{imm_b_type[12]}}, imm_b_type};
    wire [31:0] branch_target_wire = pc_current_wire + imm_32_branch;
    wire branch_wire = (opcode_wire == 7'b1100011);
    wire pc_src_wire = branch_wire & zero_flag_wire;
    
    PC pc(
        .clk(clk),
        .rst(rst),
        .pc_src(pc_src_wire),
        .branch_target(branch_target_wire),
        .pc_out(pc_current_wire)
    );
    
    INST_MEM inst_mem(
        .clk(clk),
        .we(we),
        .write_data(data_ext),
        .outside_address(addr_ext),
        .pc_address(pc_current_wire),
        .instruction(inst_wire)
    );
    
    DECODER decoder(
        .inst(inst_wire),
        .opcode(opcode_wire),
        .rd(rd_wire),
        .funct3(funct3_wire),
        .rs1(rs1_wire),
        .rs2(rs2_wire),
        .funct7(funct7_wire),
        .imm_12(imm_12_wire)
    );
    
    REG_FILE reg_file(
        .clk(clk),
        .we(reg_write_wire),
        .rs1_addr(rs1_wire),
        .rs2_addr(rs2_wire),
        .rd_addr(rd_wire),
        .write_data(alu_result_wire),
        .rs1_data(rs1_data_wire),
        .rs2_data(rs2_data_wire),
        .debug_addr(sw_reg_select),
        .debug_data(debug_reg_data_wire)
    );
    
    CONTROL_UNIT ctrl_unit_inst (
        .opcode(opcode_wire),
        .reg_write(reg_write_wire),
        .alu_src(alu_src_wire),
        .alu_op(alu_op_wire),
        .mem_write(mem_write_wire),
        .mem_read(mem_read_wire),
        .mem_to_reg(mem_to_reg_wire)
    );
    ALU_CONTROL alu_ctrl(
        .ALUOp(alu_op_wire),
        .funct3(funct3_wire),
        .funct7(funct7_wire),
        .alu_control(alu_control_signal)
    );
    ALU alu(
        .rs1_data(rs1_data_wire),
        .rs2_data(rs2_data_wire),
        .imm(imm_32_ext_wire),
        .alu_src(alu_src_wire),
        .alu_control(alu_control_signal),
        .result(alu_result_wire),
        .zero(zero_flag_wire)
    );
    assign lcd_val_out = debug_reg_data_wire;
    assign led_out = pc_current_wire[24]; 
    
    
    
    
endmodule