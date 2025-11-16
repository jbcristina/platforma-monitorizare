
# 🛠️ Platforma de Monitorizare a Starii unui Sistem

## Clonare proiect

Pentru a clona acest proiect creați propriul vostru repository EMPTY în GitHub și rulați pas cu pas comenzile de mai jos:
```bash
git clone git@git@git@github.com:jbcristina/platforma-monitorizare.git
cd platforma-monitorizare
git remote -v
git remote remove origin
git remote add origin git@github.com:<USERUL_VOSTRU>/platforma-monitorizare.git
git branch -M main
git push -u origin main
```

## Scopul Proiectului
Scopul acestui proiect este să monitorizeze în timp real starea unui sistem (mașină virtuală, container etc.) și să mențină o istorie a stărilor pentru analiză ulterioară. Aplicația colectează informații despre CPU, memorie, procese active, utilizare disk și alte date relevante, le salvează într-un fișier de log, iar un script Python face backup automat doar când apar modificări. Totul este containerizat, orchestrat în Kubernetes, automatizat cu Ansible și integrat într-un pipeline CI/CD cu Jenkins.

### Arhitectura proiectului
Arhitectura include:
- Două containere: unul pentru monitorizare (shell), altul pentru backup (Python)
- Un container Nginx care expune fișierul de log
- Orchestrare în Kubernetes cu HPA
- Provisionare cu Ansible pe o mașină virtuală
- CI/CD cu Jenkins


## Structura Proiectului

![Structura proiectului](/imagini/structura_proiect.png)

- `/scripts`: 
    - `monitoring.sh`: script shell care colectează date despre sistem (CPU, memorie, uptime, procese, disk).
    - `backup.py`: script Python care face backup la fișierul de log dacă acesta s-a modificat.

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
    - `inventory.ini`: definește VM-urile țintă.

- `/jenkins/pipelines`:
    - `monitoring/Jenkinsfile`: pipeline CI/CD pentru scriptul shell.
    - `backup/Jenkinsfile`: pipeline CI/CD pentru scriptul Python.

- `/terraform`:
    - `main.tf`: creează infrastructura AWS (EC2, S3, SSH key-pair).
    - `backend.tf`: salvează state-ul Terraform în S3.


## Setup și Rulare

🖥️ `scripts/monitoring.sh`
- Suprascrie fișierul `system-state.log` la fiecare ciclu;
- Intervalul este configurabil cu `export MONITOR_INTERVAL=10`.

💾 `scripts/backup.py`
- Creează backup doar dacă fișierul s-a modificat;
- Numele backup-ului include data și ora;
- Directorul de backup este configurabil cu `export BACKUP_DIR=backup`;
- Logurile sunt clare și informative;
- Tratează toate excepțiile fără a se opri.

⚙️ Variabile de mediu

| Variabilă      | Descriere   | Valoare implicită                          |
|:------------------|:--------:|-----------------------------------:|
| MONITOR_INTERVAL     | Intervalul de monitorizare în secunde     | 5 |
| BACKUP_INTERVAL      | Intervalul de verificare pentru backup   | 5     |
| BACKUP_DIR         | Directorul unde se salvează backup-urile   | backup    |

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

## Setup și Rulare Docker

### 1️⃣ Containerul de monitorizare:
```bash
# Build:
cd /home/cris/work/platforma-monitorizare
docker build -t monitorizare -f docker/monitoring/Dockerfile .

#Testare individuala:
docker run --rm -e MONITORING_INTERVAL=5 -v "$(pwd)/scripts:/scripts" monitorizare
docker exec -it monitorizare sh
```
Se verifică fișierul scripts/system-state.log — ar trebui să fie suprascris la fiecare 5 secunde cu informații despre sistem.

### 2️⃣  Containerul de backup:
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
Logurile din terminal confirmă acțiunile: detectare modificare, creare backup, rotație fișiere.

### 3️⃣  Rularea ambelor containere simultan cu Docker Compose:
```bash
# Build:
cd /home/cris/work/platforma-monitorizare
docker compose -f docker/compose.yaml up --build

#Verificare loguri:
Attaching to backup, monitorizare
backup  | 2025-11-15 16:45:34,720 - INFO - Pornit script de backup cu interval de 5 secunde.
backup  | 2025-11-15 16:45:34,721 - INFO - Fișierul s-a modificat. Se face backup...
backup  | 2025-11-15 16:45:34,721 - INFO - Backup creat: scripts/backup/system-state_20251115_164534.log
backup  | 2025-11-15 16:45:34,722 - INFO - Backup vechi șters: scripts/backup/system-state_20251115_164302.log
monitorizare  | [INFO] Logul a fost scris cu succes în scripts/system-state.log
backup        | 2025-11-15 16:45:39,731 - INFO - Fișierul s-a modificat. Se face backup...
backup        | 2025-11-15 16:45:39,732 - INFO - Backup creat: scripts/backup/system-state_20251115_164539.log
backup        | 2025-11-15 16:45:39,732 - INFO - Backup vechi șters: scripts/backup/system-state_20251115_164307.log
monitorizare  | [INFO] Logul a fost scris cu succes în scripts/system-state.log
backup        | 2025-11-15 16:45:44,737 - INFO - Fișierul s-a modificat. Se face backup...

#Într-un alt terminal:
docker exec -it backup sh
/ # tail -f scripts/system-state.log
/ # ls -l scripts/backup/
```
🔎 Se verifică că:
- system-state.log este actualizat periodic
- fișierele de backup apar în scripts/backup/
- se păstrează maxim 10 backupuri (sau cât este setat în MAX_BACKUPS)

### ▶️ Oprirea containerelor și curățare imagini și volume:
```bash
docker compose -f docker/compose.yaml down
docker system prune -a
```

## Setup și Rulare Ansible pe mașina nouă
```bash
#Pe mașina client citim cheia publică a userului curent:
cat ~/.ssh/id_rsa.pub

# Pe mașina remote (mașina nouă) adăugăm un user nou și îi setăm cheia de ssh
sudo adduser ansible2

# Adăugăm userul ansible2 în userii cu drept de sudo
sudo usermod -aG sudo mansible2
groups ansible2

# Adăugăm userul ansible2 în lista de useri ce nu au nevoie de parolă la sudo
cd /etc/sudoers.d/
echo "ansible2 ALL=(ALL) NOPASSWD:ALL" | sudo tee ansible2-nopasswd
# (ansible2 este userul pe care îl folosește Ansible să facă ssh pe mașina server)

su - ansible2

# Verificăm că putem face sudo fară parolă
sudo ls

# Adaugăm cheia de ssh a userului ansible2 în mașina remote. Atenție: trebuie sa fiți logati cu userul ansible când rulați aceste comenzi

mkdir .ssh
touch ~/.ssh/authorized_keys
echo “cheie ssh publica de pe masina client” >> ~/.ssh/authorized_keys
cat ~/.ssh/authorized_keys

# Instalăm ssh server pe mașina remote
sudo apt update
sudo apt install -y openssh-server
service ssh status

# Luam IP-ul mașinii remote (IP-ul care nu se termina in .1)
ip addr | grep 192.168

# Revenim pe mașina client și încercăm să facem ssh cu userul ansible2
ssh ansible2@192.168.100.82

```
### ✅ Verificare instalare Docker cu Ansible
După rularea playbook-ului `ansible/playbooks/install_docker.yml`, verifică:
```bash
cd /home/cris/work/platforma-monitorizare
ansible-playbook -i ansible/inventory.ini ansible/playbooks/install_docker.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/deploy_platform.yml

# Verifică dacă Docker este instalat
docker --version
# Verifică dacă serviciul Docker rulează
systemctl status docker
# Verifică dacă userul are acces la Docker
groups ansible2
```
Dacă ansible2 apare în grupul docker, instalarea este completă.

### ✅ Verificare rulare compose.yaml cu Ansible
După rularea playbook-ului `ansible/playbooks/deploy_platform.yml`, verifică:
```bash
# Verifică dacă fișierul compose a fost copiat
ls -l /home/ansible2/platforma-monitorizare/docker/compose.yaml

# Verifică dacă containerele rulează
docker ps

# Verifică logurile containerelor
docker logs <nume_container>
```
### ✅ Verificare funcționalitate aplicație:
```bash
# Verifică dacă fișierul system-state.log este generat
cat scripts/system-state.log

# Verifică dacă backup-ul a fost creat
ls backup/
```
### 🔍 Verificare Ansible din output:
În terminal, după rularea playbook-urilor, caută:
- changed=1 sau ok=1 pentru taskuri reușite
- failed=0 pentru a confirma că nu au fost erori
Exemplu:
```bash
PLAY RECAP ***********************************************************************************************************************************************
vm                         : ok=13   changed=4    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   

```

## Setup și Rulare in Kubernetes

### 🔹 Build imagini local în Minikube:
```bash
minikube start
eval $(minikube -p minikube docker-env) #activeaza mediul Docker din Minikube
docker build -t monitorizare -f docker/monitoring/Dockerfile .
docker build -t backup -f docker/backup/Dockerfile .
#Imaginile sunt disponibile in contextul Minikube
```
### 🔹 Aplică resursele Kubernetes:
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/hpa.yaml
```
### 🔍 Verificare:
```bash
kubectl get pods -n monitoring
kubectl get hpa -n monitoring
kubectl port-forward -n monitoring deployment/monitoring-app 8888:80
```
Se acceseaza in browser: 
http://localhost:8888/system-state.log

🖼️ Diagrama arhitecturii în Kubernetes

          +--------------------+
          |      User/Client   |
          +---------+----------+
                    |
                    v
          +--------------------+
          |     Nginx Pod      |  <- Expune logurile
          +---------+----------+
                    |
        +--------------+----------------+
        |                               |
        v                               v
    +--------+                       +--------+ 
    | Monitor|                       | Backup |
    |Container|                      |Container|
    +--------+                       +--------+

- HPA (Horizontal Pod Autoscaler) gestionează numărul de replici:   
  minReplicas = 2, maxReplicas = 10

Note:   
Monitorul generează logul de sistem periodic.   
Backup-ul verifică modificările și creează copii cu timestamp.  
Nginx expune fișierul de log pentru vizualizare externă.    
Autoscalarea se face automat pe baza metricilor CPU și memorie.

## CI/CD și Automatizari

![](/imagini/jenkins-logo.png)

Proiectul include două pipeline-uri declarative, fiecare definit într-un `Jenkinsfile` și versionat în Git:

### 🔧 Pipeline-uri

- `jenkins/pipelines/backup/Jenkinsfile`: verifică sintaxa, testează, construiește imaginea Docker și o publică
- `jenkins/pipelines/monitoring/Jenkinsfile`: construiește imaginea Docker și o publică

#### ⚙️ 1. Crearea joburilor în Jenkins
##### 🔹 1.1. platforma-monitorizare-backup
1. În Jenkins --> Dashboard --> New Item
2. Nume: platforma-monitorizare-backup
3. Tip: Pipeline
4. Click OK
5. La secțiunea Pipeline:

	Definition: Pipeline script from SCM

	SCM: Git

	Repository URL: git@github.com:jbcristina/platforma-monitorizare.git

	Credentials: jenkins

	Branch: */main

	Script Path: jenkins/pipelines/backup/Jenkinsfile
6. Click Save și Build Now

![Imagine Pipeline Backup - Blue Ocean](/imagini/platforma-monitorizare-backup.jpg)

##### 🔹 1.2. platforma-monitorizare-monitoring
1. În Jenkins --> Dashboard --> New Item
2. Nume: platforma-monitorizare-monitoring
3. Tip: Pipeline
4. Click OK
5. La secțiunea Pipeline:

	Definition: Pipeline script from SCM

	SCM: Git

	Repository URL: git@github.com:jbcristina/platforma-monitorizare.git

	Credentials: jenkins

	Branch: */main

	Script Path: jenkins/pipelines/monitoring/Jenkinsfile
6. Click Save și Build Now

![Imagine Pipeline Monitoring - Blue Ocean](/imagini/platforma-monitorizare-monitoring.jpg)


### Configurare Jenkins

#### Creează user `monitoring-user` cu acces limitat
1. Manage Jenkins --> Manage and Assign Roles --> Manage Roles.
2. Creează un rol nou: `platforma-monitorizare`
3. Permisiuni minime: 
    Overall: Read
    Job: Read, Build, Workspace, Discover
    View: Read
4. Assign Roles:
    Atribuie userului `monitoring-user` acest rol.
#### Creează view `SystemStateMonitor` care include doar joburile proiectului
1. Mergi pe Dashboard (pagina principală Jenkins)
2. Click pe “+ New View” sau accesează direct: http://localhost:8080/newView
3. Completează:
    View name: Platforma Monitorizare

    Type: List View

    Click OK

### Rulare

Pipeline-urile se declanșează automat la fiecare push în Git sau manual din Jenkins.

## Resurse
- [Sintaxa Markdown](https://www.markdownguide.org/cheat-sheet/)
- [Schelet Proiect](https://github.com/amihai/platforma-monitorizare)
- [Git - Documentatie](https://git-scm.com/docs)
- [Docker oficial](https://docs.docker.com/)
- [Docker compose](https://docs.docker.com/compose/)
- [Documentația oficială Ansible](https://docs.ansible.com/ansible/latest/index.html)
- [Documentația oficială Python 3](https://docs.python.org/3/)
- [Documentația oficială Kuberbetes](https://kubernetes.io/docs/home/)
- [Documentația oficială Minikube](https://minikube.sigs.k8s.io/docs/)
- [Documentația oficială Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/)

