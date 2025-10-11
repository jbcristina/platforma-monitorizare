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
LOG_FILE="system-state.log" 
# Funcția pentru obținerea informațiilor de sistem
get_system_info() {
        echo "==================== STARE SISTEM ===================="
        echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime -p)"
        echo "----------------------------------------"
        echo "Utilizare CPU:"
        top -bn1 | grep "Cpu(s)" | awk '{print "  User: " $2 "%, System: " $4 "%, Idle: " $8 "%"}'
        echo "Media de incarcare: $(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')"
        echo "----------------------------------------"
        echo "Utilizare memorie:"
        free -h | awk '/Mem:/ {print "  Total: " $2 ", Used: " $3 ", Free: " $4}'
        free -h | awk '/Swap:/ {print "  Swap Total: " $2 ", Used: " $3 ", Free: " $4}'
        echo "----------------------------------------"
        echo "Utilizare disk:"
        df -h / | awk 'NR==2 {print "  Total: " $2 ", Used: " $3 ", Available: " $4 ", Usage: " $5}'
        echo "----------------------------------------"
        echo "Utilizare retea:"
        IFACE=$(ip route | grep default | awk '{print $5}')
        RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
        TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
        echo "  Interfata: $IFACE"
        echo "  Primite: $((RX / 1024)) KB, Transmise: $((TX / 1024)) KB"
        echo "----------------------------------------"
        echo "Temperatura CPU:"
        sensors | grep -m 1 'Package id 0:' || echo "  Not available"
        echo "----------------------------------------"
        echo "Procese active: $(ps -e --no-headers | wc -l)"
        echo "Top 5 procese ce consuma memorie:"
        ps -eo pid,comm,%mem --sort=-%mem | head -n 6 | awk 'NR>1 {printf "  PID: %s, CMD: %s, MEM: %s%%\n", $1, $2, $3}'
        echo "----------------------------------------"
        echo "Utilizatori logati:"
        who | awk '{print "  User: " $1 ", Terminal: " $2 ", Login Time: " $3 " " $4}'
        echo "----------------------------------------"
        echo "Servicii active (systemd):"
        systemctl list-units --type=service --state=running | awk 'NR>1 && NF {print "  " $1}'
        echo "====================================================="
}   
# Loop pentru monitorizare
while true; do
    get_system_info > "$LOG_FILE"
    sleep "$INTERVAL"
done    