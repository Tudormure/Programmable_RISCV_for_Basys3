# Procesor RISCV pentru Basys3, simulabil si programabil
Simularea unui procesor in vivado in limbaj verilog si interfata pentru programarea procesorului, cat si pentru incarcarea codului assembly pe placa Basys3

REQUIREMENTS:

1. Vivado si python instalate
2. Deschiderea proiectului in Vivado si rularea simularii o data, si incarcarea bitstream-ului pe placuta
3. Pentru utilizarea GUI se genereaza un venv si se instaleaza modulul pyserial, dupa care se ruleaza scriptul ASM_IDE.py in acel venv
4. "xsim" adaugat in path la sistem variables
5. Arhitectura limiteaza alocarea constantelor direct in registrii la +2047 (7ff) respectiv -2048 (fffff800) datorita alocarii pe 2^12 biti cu un bit de semn (imm_12)

***Instructiuni:***

| **ADD** | `add rd, rs1, rs2` | Adunare pe 32 de biți: `rd = rs1 + rs2` | `add x3, x1, x2` |
| **SUB** | `sub rd, rs1, rs2` | Scădere în complement față de 2: `rd = rs1 - rs2` | `sub x3, x1, x2` |
| **AND** | `and rd, rs1, rs2` | ȘI logic (Bitwise AND): `rd = rs1 & rs2` | `and x3, x1, x2` |
| **OR** | `or rd, rs1, rs2` | SAU logic (Bitwise OR): `rd = rs1 \| rs2` | `or x3, x1, x2` |
| **SLL** | `sll rd, rs1, rs2` | Deplasare logică la stânga (Shift Left) cu `rs2[4:0]` biți | `sll x3, x1, x2` |
| **SRL** | `srl rd, rs1, rs2` | Deplasare logică la dreapta (Shift Right) cu `rs2[4:0]` biți | `srl x3, x1, x2` |
| **SLT** | `slt rd, rs1, rs2` | Set Less Than (Comparație cu semn). Dacă `rs1 < rs2`, `rd = 1`, altfel `0` | `slt x3, x1, x2` |
| **ADDI** | `addi rd, rs1, imm` | Adună o constantă: `rd = rs1 + imm` | `addi x1, x0, 15` |
| **LW** | `lw rd, imm(rs1)` | Load Word. Citește 32 biți din RAM la adresa `rs1 + imm` | `lw x5, 4(x1)` |
| **SW** | `sw rs2, imm(rs1)` | Store Word. Scrie valoarea `rs2` la adresa `rs1 + imm` | `sw x4, 0(x1)` |
| **BEQ** | `beq rs1, rs2, imm` | Branch if Equal. Dacă `rs1 == rs2`, sare la `PC = PC + imm` | `beq x1, x2, 12` |


<img width="518" height="283" alt="image" src="https://github.com/user-attachments/assets/ea01075c-40cb-403d-a676-585637e9bd39" />

(IO nu semnfica nimic, doar a fost setat un output oarecare pentru rularea raportului)

## 📂 Structura Proiectului

```text
📦 SCID_Procesor_V3
 ┣ 📂 SCID_Procesor_V3.srcs
 ┃ ┗ 📂 sources_1
 ┃   ┗ 📂 new
 ┃     ┣ 📜 FINAL_BUILD_UP.v 
 ┃     ┣ 📜 ALU.v 
 ┃     ┣ 📜 DATA_MEM.v
 ┃     ┣ 📜 CONTROL_UNIT.v
 ┃     ┗ 📜 ...
 ┣ 📜 SCID_Procesor_V3.xpr
 ┣ 🐍 ASM_IDE.py
 ┣ 📝 program.txt
 ┣ 📊 rezultate_registri.txt
