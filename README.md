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

!(/structura-proiect.png)

platforma-monitorizare/
├── ansible/
│   ├── inventory.ini
│   └── playbooks/
│       ├── deploy_platform.yml
│       └── install_docker.yml
├── docker/
│   ├── backup/
│   │   └── Dockerfile
│   ├── compose.yaml
│   └── monitoring/
│       └── Dockerfile
├── imagini/
│   └── jenkins-logo.png
├── jenkins/
│   └── pipelines/
│       ├── backup/
│       │   └── Jenkinsfile
│       └── monitoring/
│           └── Jenkinsfile
├── k8s/
│   ├── deployment.yaml
│   └── hpa.yaml
├── scripts/
│   ├── backup.py
│   └── monitoring.sh
├── terraform/
│   ├── backend.tf
│   └── main.tf
└── README.md


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

```python
import time
print("Hello World")
time.sleep(4)
```

- [Descrieti cum ati pornit containerele si cum ati verificat ca aplicatia ruleaza corect.] 
- [Includeti aici pasii detaliati de configurat si rulat Ansible pe masina noua]
- [Descrieti cum verificam ca totul a rulat cu succes? Cateva comenzi prin care verificam ca Ansible a instalat ce trebuia]

## Setup și Rulare in Kubernetes
- [Adaugati aici cateva detalii despre cum se poate rula in Kubernetes aplicatia]
- [Bonus: Adaugati si o diagrama cu containerele si setupul de Kubernetes] 

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
