`timescale 1ns / 1ps

module mux1(
    input sel,              // Semnalul de selecție (macazul de 1 bit)
    input [31:0] in0,       // Intrarea care trece dacă sel == 0
    input [31:0] in1,       // Intrarea care trece dacă sel == 1
    output [31:0] out       // Ieșirea selectată
);

    // Dacă sel este 1, ieșirea devine in1. Altfel, devine in0.
    assign out = (sel == 1'b1) ? in1 : in0;

endmodule