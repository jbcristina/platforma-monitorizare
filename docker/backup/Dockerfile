# Dockerfile pentru imaginea scriptului de backup Python.
#FROM python:3.10-slim

#WORKDIR /app
#COPY docker/backup/backup.py .

#ENV INTERVAL=5
#ENV BACKUP_DIR=/backup
#ENV MAX_BACKUPS=10

#VOLUME ["/backup"]

#CMD ["python3", "backup.py"]

FROM python:3.10-alpine

# Setăm directorul de lucru
#WORKDIR /app

# Copiem scriptul de backup
COPY scripts/backup.py /backup.py

# Instalăm dependențele necesare
RUN pip install --no-cache-dir --upgrade pip

# Declarăm volume pentru loguri și backupuri
VOLUME ["/scripts"]

# Variabile de mediu implicite
ENV INTERVAL=5
ENV BACKUP_DIR=scripts/backup
ENV MAX_BACKUPS=10

# Comanda de rulare
CMD ["python3", "backup.py"]