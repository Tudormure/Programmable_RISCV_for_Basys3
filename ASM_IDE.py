import tkinter as tk
from tkinter import scrolledtext, messagebox
import os
import subprocess
import threading
import time
import sys

# --- CONFIGURARE CĂI FIȘIERE ---
# Fixăm directorul de bază strict la locația proiectului Vivado.
# --- CONFIGURARE CĂI FIȘIERE ---
# Detectează automat folderul de unde a fost lansat executabilul sau scriptul
if getattr(sys, 'frozen', False):
    # Dacă rulează ca executabil (.exe)
    BASE_DIR = os.path.dirname(sys.executable)
else:
    # Dacă rulează ca script Python (.py)
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

FILE_PROGRAM_HEX = os.path.join(BASE_DIR, "program.txt")
FILE_RESULTS_TXT = os.path.join(BASE_DIR, "rezultate_registri.txt")
VIVADO_SIMULATE_BAT = os.path.join(BASE_DIR, "SCID_Procesor.sim", "sim_1", "behav", "xsim", "simulate.bat")
FILE_SIMULATE_LOG = os.path.join(BASE_DIR, "SCID_Procesor.sim", "sim_1", "behav", "xsim", "simulate.log")
# --- MINI ASAMBLOR RISC-V ---
def assemble_instruction(line):
    """Traduce o linie de Assembly RISC-V in Hexazecimal (32 biti)"""
    line = line.split('#')[0].strip() # Eliminam comentariile
    if not line: return None
    
    parts = line.replace(',', ' ').split()
    inst = parts[0].lower()
    
    try:
        if inst in ['add', 'sub', 'and', 'or', 'sll', 'srl', 'slt']: # R-TYPE
            rd = int(parts[1].replace('x', ''))
            rs1 = int(parts[2].replace('x', ''))
            rs2 = int(parts[3].replace('x', ''))
            
            opcode = "0110011"
            funct3 = {"add": "000", "sub": "000", "and": "111", "or": "110", "sll": "001", "srl": "101", "slt": "010"}[inst]
            funct7 = "0100000" if inst == "sub" else "0000000"
            
            # Asamblare R-Type
            bin_str = f"{funct7}{rs2:05b}{rs1:05b}{funct3}{rd:05b}{opcode}"
            return f"{int(bin_str, 2):08X}"
            
        elif inst in ['addi']: # I-TYPE
            rd = int(parts[1].replace('x', ''))
            rs1 = int(parts[2].replace('x', ''))
            imm = int(parts[3])
            
            opcode = "0010011"
            funct3 = "000"
            
            # Tratare numere negative (Complement fata de 2 pt 12 biti)
            if imm < 0: imm = (1 << 12) + imm
                
            bin_str = f"{imm:012b}{rs1:05b}{funct3}{rd:05b}{opcode}"
            return f"{int(bin_str, 2):08X}"
            
        elif inst in ['beq']: # BRANCH IF EQUAL (B-TYPE)
            rs1 = int(parts[1].replace('x', ''))
            rs2 = int(parts[2].replace('x', ''))
            imm = int(parts[3]) 
            
            opcode = "1100011"
            funct3 = "000"
            
            if imm < 0: imm = (1 << 13) + imm
            imm_bin = f"{imm:013b}"
            
            bit_31 = imm_bin[0]       # bitul 12
            bit_30_25 = imm_bin[2:8]  # biții 10:5
            bit_11_8 = imm_bin[8:12]  # biții 4:1
            bit_7 = imm_bin[1]        # bitul 11
            
            bin_str = f"{bit_31}{bit_30_25}{rs2:05b}{rs1:05b}{funct3}{bit_11_8}{bit_7}{opcode}"
            return f"{int(bin_str, 2):08X}"
            
        elif inst == 'lw':  # Load Word (I-Type)
            rd = int(parts[1].replace('x', ''))
            offset_part = parts[2].split('(')
            imm = int(offset_part[0])
            rs1 = int(offset_part[1].replace('x', '').replace(')', ''))
            
            opcode = "0000011"
            funct3 = "010"
            if imm < 0: imm = (1 << 12) + imm
            
            bin_str = f"{imm:012b}{rs1:05b}{funct3}{rd:05b}{opcode}"
            return f"{int(bin_str, 2):08X}"

        elif inst == 'sw':  # Store Word (S-Type)
            rs2 = int(parts[1].replace('x', ''))
            offset_part = parts[2].split('(')
            imm = int(offset_part[0])
            rs1 = int(offset_part[1].replace('x', '').replace(')', ''))
            
            opcode = "0100011"
            funct3 = "010"
            if imm < 0: imm = (1 << 12) + imm
            imm_bin = f"{imm:012b}"
            
            imm_11_5 = imm_bin[0:7]
            imm_4_0 = imm_bin[7:12]
            
            bin_str = f"{imm_11_5}{rs2:05b}{rs1:05b}{funct3}{imm_4_0}{opcode}"
            return f"{int(bin_str, 2):08X}"
        
        else:
            return f"EROARE: Instructiune necunoscuta '{inst}'"
    except Exception as e:
        return f"EROARE de sintaxa: {line}"

# --- CLASA APLICAȚIEI GUI ---
class RiscvIDE:
    def __init__(self, root):
        self.root = root
        self.root.title("ASM RISC-V IDE")
        self.root.geometry("1200x550")
        
        bg_color = "#2b2b2b"     
        fg_color = "#80dfff"     
        text_bg_color = "#1e1e1e" 
        
        self.root.configure(bg=bg_color)
        
        # UI Layout
        left_frame = tk.Frame(root, padx=10, pady=10, bg=bg_color)
        left_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        right_frame = tk.Frame(root, padx=10, pady=10, bg=bg_color)
        right_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True) 
        
        log_frame = tk.Frame(root, padx=10, pady=10, bg=bg_color)
        log_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        self.btn_sim = tk.Button(left_frame, text="Compile and Run Full Simulation", 
                                 bg="#6a0dad", fg="white", font=("Arial", 10, "bold"), 
                                 command=self.run_simulation)
        self.btn_sim.pack(fill=tk.X, pady=5)
        
        tk.Label(left_frame, text="Scrie cod Assembly RISC-V:", font=("Arial", 12, "bold"), 
                 bg=bg_color, fg=fg_color).pack(anchor="w")
        
        self.code_input = scrolledtext.ScrolledText(left_frame, width=40, height=20, 
                                                    font=("Consolas", 11), 
                                                    bg=text_bg_color, fg=fg_color, 
                                                    insertbackground=fg_color)
        self.code_input.pack(fill=tk.BOTH, expand=True)
        self.code_input.insert(tk.END, "addi x1, x0, 10\naddi x2, x1, 5\nadd x3, x1, x2")
        
        btn_compile = tk.Button(left_frame, text="Compilează & Salvează (program.txt)", 
                                bg="#404040", fg="white", font=("Arial", 10, "bold"), 
                                command=self.compile_code)
        btn_compile.pack(fill=tk.X, pady=5)
        
        tk.Label(right_frame, text="Rezultate (rezultate_registri.txt):", font=("Arial", 12, "bold"), 
                 bg=bg_color, fg=fg_color).pack(anchor="w")
                 
        # Butonul de UART care face si compilarea automat
        tk.Button(left_frame, text="Compilează & Încarcă pe Placă (UART)", bg="#009933", fg="white", font=("Arial", 10, "bold"), command=self.upload_via_uart).pack(fill=tk.X, pady=5)
        
        self.results_output = scrolledtext.ScrolledText(right_frame, width=40, height=20, 
                                                       font=("Consolas", 11), 
                                                       bg=text_bg_color, fg=fg_color)
        self.results_output.pack(fill=tk.BOTH, expand=True)
        
        btn_read = tk.Button(right_frame, text="Citește Rezultate de la Procesor", 
                             bg="#404040", fg="white", font=("Arial", 10, "bold"), 
                             command=self.read_results)
        btn_read.pack(fill=tk.X, pady=5)

        tk.Label(log_frame, text="Jurnal Simulare (simulate.log):", font=("Arial", 12, "bold"), 
                 bg=bg_color, fg=fg_color).pack(anchor="w")
        
        self.log_output = scrolledtext.ScrolledText(log_frame, width=40, height=20, 
                                                   font=("Consolas", 11), 
                                                   bg=text_bg_color, fg="#ffcc00") 
        self.log_output.pack(fill=tk.BOTH, expand=True)
        self.log_output.config(state=tk.DISABLED) 
        
        btn_update_log = tk.Button(log_frame, text="Update Jurnal", 
                                 bg="#404040", fg="white", font=("Arial", 10, "bold"), 
                                 command=self.read_simulation_log)
        btn_update_log.pack(fill=tk.X, pady=5)

    def upload_via_uart(self):
        # 1. Compilam codul mai intai (in mod silentios, fara popup de succes)
        if not self.compile_code(silent=True):
            return # Ne oprim daca a aparut o eroare la compilare (ex: sintaxa gresita)
            
        import serial
        
        # Setează portul corect (ex: 'COM3', 'COM7' - verifică în Device Manager)
        PORT_SERIAL = "COM7" 
        BAUD_RATE = 9600
        
        try:
            ser = serial.Serial(PORT_SERIAL, BAUD_RATE, timeout=1)
            time.sleep(1) # Lăsăm portul să se stabilizeze
            
            with open(FILE_PROGRAM_HEX, "r") as f:
                lines = f.readlines()
                
            for line in lines:
                line = line.strip()
                if not line: continue
                
                # Transformăm string-ul Hex de 8 caractere în valoare numerică
                inst_int = int(line, 16)
                # Convertim în 4 bytes în format Little-Endian
                bytes_to_send = inst_int.to_bytes(4, byteorder='little')
                
                # Trimitem cei 4 bytes prin serial
                ser.write(bytes_to_send)
                time.sleep(0.05) # Scurtă pauză necesară pentru scrierea în BRAM a FPGA-ului 
                
            ser.close()
            messagebox.showinfo("Succes Serial", "Programul a fost compilat și trimis pe placă prin UART!")
        except Exception as e:
            messagebox.showerror("Eroare Serială", f"Nu s-a putut trimite programul:\n{str(e)}")

    def read_simulation_log(self):
        if not os.path.exists(FILE_SIMULATE_LOG):
            return # Ascundem avertismentul ca sa nu deranjeze la auto-update
            
        try:
            with open(FILE_SIMULATE_LOG, "r") as f:
                content = f.read()
            self.log_output.config(state=tk.NORMAL)   
            self.log_output.delete("1.0", tk.END)     
            self.log_output.insert(tk.END, content)   
            self.log_output.config(state=tk.DISABLED) 
        except Exception as e:
            messagebox.showerror("Eroare", f"Nu am putut citi fișierul log:\n{str(e)}")
    def run_simulation(self):
        # --- TEST DIAGNOSTICARE PATH ---
        if not os.path.exists(VIVADO_SIMULATE_BAT):
            messagebox.showerror("Eroare de Cale (Debug)", 
                                 f"Nu găsesc simulate.bat!\n\n"
                                 f"Calea pe care o caut este:\n{VIVADO_SIMULATE_BAT}\n\n"
                                 f"BASE_DIR a fost calculat ca:\n{BASE_DIR}")
            return
        # -------------------------------
        # 1. Compilăm și salvăm codul automat înainte de simulare
        # Folosim silent=True pentru a nu primi popup cu "Succes" la fiecare rulare
        if not self.compile_code(silent=True):
            return # Ne oprim aici dacă există erori de sintaxă în Assembly
            
        # 2. Dacă compilarea a reușit, pornim simularea
        self.btn_sim.config(text="SE PREGĂTEȘTE...", bg="#cc0000", state=tk.DISABLED)
        thread = threading.Thread(target=self._run_sim_thread)
        thread.daemon = True 
        thread.start()

    def _run_sim_thread(self):
        sim_dir = os.path.dirname(VIVADO_SIMULATE_BAT)
        vivado_bin = r"C:\Xilinx\Vivado\2025.2\bin" 
        
        my_env = os.environ.copy()
        my_env["PATH"] = vivado_bin + os.pathsep + my_env["PATH"]

        os.system("taskkill /f /im xsim.exe /t >nul 2>&1")
        os.system("taskkill /f /im xsimk.exe /t >nul 2>&1")

        if os.path.exists(FILE_RESULTS_TXT):
            os.remove(FILE_RESULTS_TXT)

        try:
            # --- PASUL 1: COMPILARE ---
            self.root.after(0, lambda: self.btn_sim.config(text="[1/3] SE COMPILEAZĂ VERILOG..."))
            subprocess.run("compile.bat", cwd=sim_dir, env=my_env, shell=True, check=True)

            # --- PASUL 2: ELABORARE (Aici se creează noul hardware!) ---
            self.root.after(0, lambda: self.btn_sim.config(text="[2/3] SE ELABOREAZĂ ARHITECTURA..."))
            subprocess.run("elaborate.bat", cwd=sim_dir, env=my_env, shell=True, check=True)

            # --- PASUL 3: SIMULARE ---
            self.root.after(0, lambda: self.btn_sim.config(text="[3/3] SE SIMULEAZĂ..."))
            process = subprocess.Popen(
                ["simulate.bat"], 
                cwd=sim_dir, 
                env=my_env,
                shell=True,
                creationflags=subprocess.CREATE_NO_WINDOW
            )

            # Polling - Așteptăm fișierul
            timp_asteptat = 0
            succes = False
            
            while timp_asteptat < 30:
                if os.path.exists(FILE_RESULTS_TXT):
                    time.sleep(1) # Oferim o secundă extra lui Vivado pentru $fclose
                    succes = True
                    break 
                
                time.sleep(1)
                timp_asteptat += 1

            os.system("taskkill /f /im xsim.exe /t >nul 2>&1")
            os.system("taskkill /f /im xsimk.exe /t >nul 2>&1")

            if succes:
                # AUTO-UPDATE INTERFAȚĂ LA FINAL!
                self.root.after(0, self.read_results)
                self.root.after(0, self.read_simulation_log)
                self.root.after(0, lambda: messagebox.showinfo("Succes", "Simulare completată cu succes!"))
            else:
                self.root.after(0, lambda: messagebox.showerror("Timeout", "Simularea a durat prea mult."))

        except subprocess.CalledProcessError as e:
            self.root.after(0, lambda e=e: messagebox.showerror("Eroare Vivado", f"A eșuat compilarea sau elaborarea!\nVerifică codul Verilog.\nDetalii: {e}"))
        except Exception as e:
            self.root.after(0, lambda e=e: messagebox.showerror("Eroare Python", str(e)))
            
        finally:
            self.root.after(0, lambda: self.btn_sim.config(text="Compile and Run Full Simulation", bg="#6a0dad", state=tk.NORMAL))

    # Am adaugat un parametru "silent" pentru a nu deranja cu popup-ul la upload
    def compile_code(self, silent=False):
        code = self.code_input.get("1.0", tk.END).strip().split('\n')
        hex_lines = []
        
        for line in code:
            hex_val = assemble_instruction(line)
            if hex_val:
                if "EROARE" in hex_val:
                    messagebox.showerror("Eroare de Compilare", hex_val)
                    return False # <--- Se opreste si raporteaza eroarea
                hex_lines.append(hex_val)
                
        try:
            with open(FILE_PROGRAM_HEX, "w") as f:
                f.write('\n'.join(hex_lines))
            if not silent: # Afiseaza popup-ul doar daca se foloseste butonul clasic de compilare
                messagebox.showinfo("Succes", f"Compilat cu succes!\nAu fost generate {len(hex_lines)} instrucțiuni.")
            return True # <--- Confirma succesul catre functia de UART
        except Exception as e:
            messagebox.showerror("Eroare Fisier", f"Nu am putut salva fisierul:\n{str(e)}")
            return False

    def read_results(self):
        if not os.path.exists(FILE_RESULTS_TXT):
            messagebox.showwarning("Lipsă fișier", "Nu am găsit fișierul de rezultate!")
            return
        try:
            with open(FILE_RESULTS_TXT, "r") as f:
                content = f.read()
            self.results_output.config(state=tk.NORMAL)
            self.results_output.delete("1.0", tk.END)
            self.results_output.insert(tk.END, content)
            self.results_output.config(state=tk.DISABLED) 
        except Exception as e:
            messagebox.showerror("Eroare", f"Nu am putut citi fișierul:\n{str(e)}")

if __name__ == "__main__":
    root = tk.Tk()
    app = RiscvIDE(root)
    root.mainloop()