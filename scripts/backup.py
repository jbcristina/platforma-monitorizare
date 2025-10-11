# Script Python pentru efectuarea backup-ului logurilor de sistem.
# ○	Un script python ce face backup la fișierul system-state.log
# ■	Backup-ul trebuie să fie făcut doar dacă fișierul s-a modificat.
# ■	Perioada la care se face backup este primită ca variabilă de mediu cu valoarea implicită 5 secunde.
# ■	Fișierul de backup trebuie să conțină în nume și data la care a fost efectuat backup-ul.
# ■	Directorul în care se fac backup-urile este primit ca variabilă de mediu cu valoare implicită backup.
# ■	Scriptul trebuie să printeze loguri relevante și suficiente pentru investigarea unei eventuale erori. 
# ■	Scriptul trebuie să trateze toate cazurile de excepție și să nu se termine cu eroare.

import os
import time
import shutil
import hashlib
from datetime import datetime

# Configurații din variabile de mediu
INTERVAL = int(os.getenv("INTERVAL", 5))
BACKUP_DIR = os.getenv("BACKUP_DIR", "/home/cris/work/platforma-monitorizare/backup")
MAX_BACKUPS = int(os.getenv("MAX_BACKUPS", 10))
SOURCE_FILE = "system-state.log"

# Asigură existența directorului de backup
try:
    os.makedirs(BACKUP_DIR, exist_ok=True)
except Exception as e:
    print(f"[ERROR] Nu s-a putut crea directorul de backup: {e}")

print(f"[INFO] Pornit script de backup cu interval de {INTERVAL} secunde.")
last_hash = None

while True:
    try:
        if not os.path.exists(SOURCE_FILE):
            print(f"[WARN] Fișierul sursă '{SOURCE_FILE}' nu există.")
        else:
            try:
                with open(SOURCE_FILE, "rb") as f:
                    current_hash = hashlib.sha256(f.read()).hexdigest()
            except Exception as e:
                print(f"[WARN] Nu s-a putut calcula hash-ul fișierului: {e}")
                current_hash = None

            if current_hash and current_hash != last_hash:
                print("[INFO] Fișierul s-a modificat. Se face backup...")
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_name = f"system-state_{timestamp}.log"
                backup_path = os.path.join(BACKUP_DIR, backup_name)
                try:
                    shutil.copy2(SOURCE_FILE, backup_path)
                    print(f"[INFO] Backup creat: {backup_path}")
                    last_hash = current_hash
                except Exception as e:
                    print(f"[ERROR] Eroare la crearea backup-ului: {e}")

                # Rotație backupuri
                try:
                    backups = sorted(
                        [f for f in os.listdir(BACKUP_DIR) if f.startswith("system-state_")],
                        key=lambda x: os.path.getmtime(os.path.join(BACKUP_DIR, x))
                    )
                    if len(backups) > MAX_BACKUPS:
                        for old_file in backups[:len(backups) - MAX_BACKUPS]:
                            old_path = os.path.join(BACKUP_DIR, old_file)
                            os.remove(old_path)
                            print(f"[INFO] Backup vechi șters: {old_path}")
                except Exception as e:
                    print(f"[WARN] Eroare la rotația backupurilor: {e}")
            else:
                print("[INFO] Fișierul nu s-a modificat. Nu se face backup.")
    except Exception as e:
        print(f"[ERROR] Eroare neașteptată: {e}")
    time.sleep(INTERVAL)

