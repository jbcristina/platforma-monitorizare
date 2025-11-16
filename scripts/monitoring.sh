# Script bash pentru monitorizarea resurselor sistemului.
# ○	Un script shell care scrie la un anumit interval de timp într-un fișier system-state.log următoarele 
# informații legate de sistem: cpu, memorie, numărul de procese active și utilizare disk (disk usage), 
# hostname si orice alta informatie considerati relevanta despre starea sistemului.
# ■	La fiecare rulare, scriptul suprascrie conținutul fișierului system-state.log.
# ■	Perioada la care se printează în fișierul system-state.log este primită ca variabilă de mediu cu 
# valoarea implicită 5 secunde.
# ■	Informațiile adăugate în fișier trebuie să fie adăugate într-un mod cât mai ușor de urmărit de către utilizator.

#!/bin/bash

# Setarea intervalului de timp pentru monitorizare
INTERVAL=${MONITORING_INTERVAL:-5}

# Fișierul de log
LOG_FILE="scripts/system-state.log"

# Funcția pentru obținerea informațiilor de sistem
get_system_info() {
    {
        echo "[INFO] ==================== STAREA SISTEMULUI ===================="
        echo "[INFO] Data si ora: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "[INFO] Hostname: $(hostname)"
        echo "[INFO] Uptime: $(uptime -p)"
        echo "[INFO] ----------------------------------------"
        echo "[INFO] Utilizare CPU:"
        top -bn1 | grep "Cpu(s)" | awk '{print "[INFO]   User: " $2 "%, System: " $4 "%, Idle: " $8 "%"}'
        echo "[INFO] Media de incarcare: $(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')"
        echo "[INFO] ----------------------------------------"
        echo "[INFO] Utilizare memorie:"
        free -h | awk '/Mem:/ {print "[INFO]   Total: " $2 ", Used: " $3 ", Free: " $4}'
        free -h | awk '/Swap:/ {print "[INFO]   Swap Total: " $2 ", Used: " $3 ", Free: " $4}'
        echo "[INFO] ----------------------------------------"
        echo "[INFO] Utilizare disk:"
        df -h / | awk 'NR==2 {print "[INFO]   Total: " $2 ", Used: " $3 ", Available: " $4 ", Usage: " $5}'
        echo "[INFO] ----------------------------------------"
        echo "[INFO] Utilizare retea:"
        IFACE=$(ip route | grep default | awk '{print $5}')
        if [[ -n "$IFACE" && -f "/sys/class/net/$IFACE/statistics/rx_bytes" ]]; then
            RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
            TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
            echo "[INFO]   Interfata: $IFACE"
            echo "[INFO]   Primite: $((RX / 1024)) KB, Transmise: $((TX / 1024)) KB"
        else
            echo "[WARN]   Interfața de rețea $IFACE nu este disponibilă sau nu are fișierele de statistică."
        fi
        echo "[INFO] ----------------------------------------"
        echo "[INFO] Temperatura CPU:"
        sensors | grep -m 1 'Package id 0:' | sed 's/^/[INFO] /' || echo "[WARN]   Temperatura CPU nu este disponibilă"
        echo "[INFO] ----------------------------------------"
        echo "[INFO] Procese active: $(ps -e --no-headers | wc -l)"
        echo "[INFO] Top 5 procese ce consuma memorie:"
        ps -eo pid,comm,%mem --sort=-%mem | head -n 6 | awk 'NR>1 {printf "[INFO]   PID: %s, CMD: %s, MEM: %s%%\n", $1, $2, $3}'
        echo "[INFO] ----------------------------------------"
        echo "[INFO] Utilizatori logati:"
        who | awk '{print "[INFO]   User: " $1 ", Terminal: " $2 ", Login Time: " $3 " " $4}'
        echo "[INFO] ----------------------------------------"
        echo "[INFO] Servicii active (systemd):"
        if command -v systemctl >/dev/null 2>&1; then
            systemctl list-units --type=service --state=running | awk 'NR>1 && NF {print "[INFO]   " $1}'
        else
            echo "[WARN]   systemctl nu este disponibil în acest mediu."
        fi
        echo "[INFO] ====================================================="
    } > "$LOG_FILE"

    if [[ $? -eq 0 ]]; then
        echo "[INFO] Logul a fost scris cu succes în $LOG_FILE"
    else
        echo "[ERROR] Eroare la scrierea în fișierul $LOG_FILE"
    fi
}

# Loop pentru monitorizare
while true; do
    get_system_info
    sleep "$INTERVAL"
done