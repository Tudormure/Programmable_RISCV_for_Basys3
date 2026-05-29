`timescale 1ns / 1ps

module FINAL_BUILD_sim();
    reg clk;
    reg rst;
    reg we;
    reg [31:0] addr_ext;
    reg [31:0] data_ext;
    integer i;
    integer out_file;
    
    wire led_dummy;
    wire [31:0] lcd_dummy;
    reg [4:0] sw_dummy = 5'b00000;
    
    FINAL_BUILD_UP uut (
        .clk(clk),
        .rst(rst),
        .we(we),
        .addr_ext(addr_ext),
        .data_ext(data_ext),
        .led_out(led_dummy),
        .sw_reg_select(sw_dummy),
        .lcd_val_out(lcd_dummy)
    );
    
    reg [31:0] program_buffer [0:999];
    
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        we = 0;
        addr_ext = 0;
        data_ext = 0;

        #20; 
        we = 1;  

        for (i = 0; i <= 999; i = i + 1) begin
            program_buffer[i] = 32'bx;
        end
        
        $readmemh("../../../../program.txt", program_buffer);
        we = 1;   
        i = 0;

        while (program_buffer[i] !== 32'bx) begin
            addr_ext = i * 4;            
            data_ext = program_buffer[i]; 
            #10;                          
            i = i + 1;                    
        end

        $display("%0d instructiuni in memorie", i);

        we = 0;
        rst = 0;
        $display("--- Procesorul ruleaza... ---");
        
        #900;
        
        out_file = $fopen("../../../../rezultate_registri.txt", "w");

        if (out_file == 0) begin
            $display("EROARE: Nu am putut deschide fisierul de iesire!");
        end else begin
            $fdisplay(out_file, "--- Starea finala a Registrilor ---");
            
            for (i = 0; i < 32; i = i + 1) begin
                $fdisplay(out_file, "x%0d = %h", i, uut.reg_file.registers[i]);
            end
            
            $fdisplay(out_file, "-----------------------------------");
            $fclose(out_file);
            $display("Succes: Rezultatele au fost salvate in rezultate_registri.txt");
        end
        $finish;
    end
endmodule