**Acest schelet de proiect si acest README.MD sunt orientative.** 
**Aveti libertatea de a aduga alte fisiere si a modifica acest schelet cum doriti. Important este sa implementati proiectul conform cerintelor primite.**
**Acest text si tot textul ajutator de mai jos trebuiesc sterse inainte de a preda proiectul.**

**Pentru a clona acest proiect creati propriul vostru proiect EMPTY in gihub si rulati:**
```bash
git clone git@github.com:amihai/platforma-monitorizare.git
cd platforma-monitorizar
git remote -v
git remote remove origin
git remote add origin:<USERUL_VOSTRU>/platforma-monitorizare.git
git branch -M main
git push -u origin main
```


# Platforma de Monitorizare a Starii unui Sistem

## Scopul Proiectului
Această aplicație monitorizează starea unui sistem (mașină virtuală, container etc.) și salvează periodic informații relevante despre resursele utilizate. Datele sunt arhivate automat pentru analiză ulterioară. Proiectul este containerizat cu Docker, orchestrat cu Kubernetes, automatizat cu Ansible, integrat în pipeline-uri CI/CD cu Jenkins și susținut de infrastructură creată cu Terraform.

### Arhitectura proiectului

![Structura proiectului](/imagini/structura_proiect.png)

## Structura Proiectului
- `/scripts`: 
    - `monitoring.sh`: script shell care colectează date despre sistem (CPU, memorie, uptime, procese, disk).
    - `backup.py`: script Python care face backup la fișierul de log dacă acesta s-a modificat

- `/docker`: 
    - `monitoring/Dockerfile`: imagine Docker pentru scriptul de monitorizare
    - `backup/Dockerfile`: imagine Docker pentru scriptul de backup.
    - `compose.yaml`: pornește ambele containere și le conectează prin volume comune.

- `/k8s`:
    - `deployment.yaml`: definește un pod cu 3 containere (monitor, backup, nginx).
    - `hpa.yaml`: autoscaler pe baza CPU și memorie.

- `/ansible`:
    - `install_docker.yml`: instalează Docker pe o mașină virtuală.
    - `deploy_platform.yml`: rulează aplicația folosind docker-compose.yaml.
    - `inventory.ini`: definește VM-urile țintă

- `/jenkins/pipelines`:
    - `monitoring/Jenkinsfile`: pipeline CI/CD pentru scriptul shell.
    - `backup/Jenkinsfile`: pipeline CI/CD pentru scriptul Python.

- `/terraform`:
    - `main.tf`: creează infrastructura AWS (EC2, S3, SSH key-pair).
    - `backend.tf`: salvează state-ul Terraform în S3.


## Setup și Rulare
- [Instrucțiuni de setup local și remote. Aici trebuiesc puse absolut toate informatiile necesare pentru a putea instala si rula proiectul. De exemplu listati aici si ce tool-uri trebuiesc instalate (Ansible, SSH config, useri, masini virtuale noi daca este cazul, etc) pasii de instal si comenzi].
- [Cand includeti instructiuni folositi blocul de code markdown cu limbajul specific codului ]

🖥️ scripts/monitoring.sh
- Suprascrie fișierul `system-state.log` la fiecare ciclu
- Intervalul este configurabil cu `export MONITOR_INTERVAL=10`

💾 scripts/backup.py
- Creează backup doar dacă fișierul s-a modificat
- Numele backup-ului include data și ora
- Directorul de backup este configurabil cu `export BACKUP_DIR=backup`
- Logurile sunt clare și informative
- Tratează toate excepțiile fără a se opri

⚙️ Variabile de mediu
| Variabilă      | Descriere   | Valoare implicită                          |
|:------------------|:--------:|-----------------------------------:|
| MONITOR_INTERVAL     | Intervalul de monitorizare în secunde     | 5 |
| BACKUP_INTERVAL      | ntervalul de verificare pentru backup   | 5     |
| BACKUP_DIR         | irectorul unde se salvează backup-urile   | backup    |

Se pot suprascrie cu:
```bash
export MONITOR_INTERVAL=10
export BACKUP_INTERVAL=10
export BACKUP_DIR=/home/cris/work/platforma-monitorizare/backup
```
Recomandare de rulare:
```bash
# Rulare monitorizare
cd /home/cris/work/platforma-monitorizare
export MONITOR_INTERVAL=5
bash scripts/monitoring.sh

# Rulare backup
export BACKUP_INTERVAL=5
export BACKUP_DIR=/home/cris/work/platforma-monitorizare/backup
python3 scripts/backup.py
```

-> Crearea imaginilor Docker
- Containerul de monitorizare:
```bash
# Build:
cd /home/cris/work/platforma-monitorizare
docker build -t monitorizare -f docker/monitoring/Dockerfile .
#Testare individuala:
docker run --rm -e MONITORING_INTERVAL=5 -v "$(pwd)/scripts:/scripts" monitorizare
docker exec -it monitorizare sh
```
Se verifică fișierul scripts/system-state.log — ar trebui să fie suprascris la fiecare 5 secunde cu informații despre sistem.

- Containerul de backup:
```bash
# Build:
cd /home/cris/work/platforma-monitorizare
docker build -t backup -f docker/backup/Dockerfile .
#Testare individuala:
docker run --rm -e INTERVAL=5 -e BACKUP_DIR=scripts/backup -e MAX_BACKUPS=10 -v "$(pwd)/scripts:/scripts" backup
docker exec -it backup sh
```
Scriptul citește scripts/system-state.log.
Dacă fișierul se modifică, creează backupuri în scripts/backup/.
Păstrează maxim 10 fișiere (sau cât se seteaza prin MAX_BACKUPS).
Logurile din terminal confirmă acțiunile: detectare modificare, creare backup, rotație fișiere

- Rularea ambelor containere simultan cu Docker Compose:
```bash
# Build:
cd /home/cris/work/platforma-monitorizare
docker compose -f docker/compose.yaml up --build
#Verificare loguri:
Attaching to backup, monitorizare
backup  | 2025-10-27 19:54:55,155 - INFO - Pornit script de backup cu interval de 5 secunde.
backup  | 2025-10-27 19:54:55,155 - INFO - Pornit script de backup cu interval de 5 secunde.
backup  | 2025-10-27 19:54:55,157 - INFO - Fișierul s-a modificat. Se face backup...
backup  | 2025-10-27 19:54:55,157 - INFO - Backup creat: scripts/backup/system-state_20251027_195455.log
backup  | 2025-10-27 19:54:55,157 - INFO - Fișierul s-a modificat. Se face backup...
backup  | 2025-10-27 19:54:55,157 - INFO - Backup creat: scripts/backup/system-state_20251027_195455.log

backup  | 2025-10-27 19:54:55,158 - INFO - Backup vechi șters: scripts/backup/system-state_20251027_184435.log
backup  | 2025-10-27 19:55:00,164 - INFO - Fișierul s-a modificat. Se face backup...
#Într-un alt terminal:
docker exec -it backup sh
/ # tail -f scripts/system-state.log
/ # ls -l scripts/backup/
```
🔎 Se verifică că:
- system-state.log este actualizat periodic
- fișierele de backup apar în scripts/backup/
- se păstrează maxim 10 backupuri (sau cât este setat în MAX_BACKUPS)

- Oprirea containerelor și curățare imagini și volume:
```bash
docker compose -f docker/compose.yaml down
docker system prune -a
```



- [Includeti aici pasii detaliati de configurat si rulat Ansible pe masina noua]
- [Descrieti cum verificam ca totul a rulat cu succes? Cateva comenzi prin care verificam ca Ansible a instalat ce trebuia]

## Setup și Rulare in Kubernetes
- [Adaugati aici cateva detalii despre cum se poate rula in Kubernetes aplicatia]
- [Bonus: Adaugati si o diagrama cu containerele si setupul de Kubernetes] 

flowchart TB
    subgraph NS["🧭 Namespace: monitoring"]
        subgraph DEP["🔁 Deployment: monitoring-app\nReplicas: 2"]
            POD1["🧱 Pod #1"]
            POD2["🧱 Pod #2"]
        end
    end

    POD1 --> C1["Container: monitorizare\n🖥️ Rulează monitoring.sh\n📝 Scrie system-state.log"]
    POD1 --> C2["Container: backup\n📦 Rulează backup.py\n🔄 Creează backup-uri"]
    POD1 --> C3["Container: nginx\n🌐 Servește system-state.log pe HTTP:80"]
    POD1 --> VOL["📂 Volume: shared-logs (emptyDir)\nPartajat între containere"]

    POD2 --> C1b["Container: monitorizare"]
    POD2 --> C2b["Container: backup"]
    POD2 --> C3b["Container: nginx"]
    POD2 --> VOLb["📂 shared-logs (emptyDir)"]

    subgraph HPA["📈 HPA: monitoring-hpa"]
        HPA1["Target: Deployment monitoring-app"]
        HPA2["Min replicas: 2"]
        HPA3["Max replicas: 10"]
        HPA4["Metrics: CPU & Memory"]
    end

    subgraph ACCESS["🌐 Acces extern"]
        A1["kubectl port-forward"]
        A2["Service: NodePort / LoadBalancer"]
        A3["Ingress: acces prin domeniu"]
    end

    HPA --> DEP
    C3 --> ACCESS


## CI/CD și Automatizari
- [Descriere pipeline-uri Jenkins. Puneti aici cat mai detaliat ce face fiecare pipeline de jenkins cu poze facute la pipeline in Blue Ocean. Detaliati cat puteti de mult procesul de CI/CD folosit.]
- [Detalii cu restul cerintelor de CI/CD (cum ati creat userul nou ce are access doar la resursele proiectului, cum ati creat un View now pentru proiect, etc)]
- [Daca ati implementat si punctul E optional atunci detaliati si setupul de minikube.]


## Terraform și AWS
- [Prerequiste]
- [Instrucțiuni pentru rularea Terraform și configurarea AWS]
- [Daca o sa folositi pentru testare localstack in loc de AWS real puneti aici toti pasii pentru install localstack.]
- [Adaugati instructiunile pentru ca verifica faptul ca Terraform a creat corect infrastructura]

## Depanare si investigarea erorilor
- [Descrieti cum putem accesa logurile aplicatiei si cum ne logam pe fiecare container pentru eventualele depanari de probleme]
- [Descrieti cum ati gandit logurile (formatul logurilor, levelul de log)]


## Resurse
- [Listati aici orice link catre o resursa externa il considerti relevant]
- Exemplu de URL:
- [Sintaxa Markdown](https://www.markdownguide.org/cheat-sheet/)
- [Schelet Proiect](https://github.com/amihai/platforma-monitorizare)
