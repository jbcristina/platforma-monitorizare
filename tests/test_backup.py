# Testează scriptul backup.py. Acest test verifică dacă fișierul de backup este generat corect și conține date relevante despre sistem.
import os
import glob
import pytest

BACKUP_DIR = "scripts/backup"
FILENAME_PATTERN = "system-state_*.log"

def test_backup_file_exists():
    """Verifică dacă există cel puțin un fișier de backup generat."""
    files = glob.glob(os.path.join(BACKUP_DIR, FILENAME_PATTERN))
    assert len(files) > 0, "Nu s-a găsit niciun fișier de backup."

def test_backup_file_not_empty():
    """Verifică dacă fișierul de backup conține date."""
    files = glob.glob(os.path.join(BACKUP_DIR, FILENAME_PATTERN))
    assert files, "Nu există fișiere de backup pentru a fi testate."
    latest = max(files, key=os.path.getctime)
    with open(latest, "r") as f:
        content = f.read().strip()
    assert len(content) > 0, "Fișierul de backup este gol."

def test_backup_file_contains_expected_keywords():
    """Verifică dacă fișierul conține informații despre CPU, RAM sau procese."""
    files = glob.glob(os.path.join(BACKUP_DIR, FILENAME_PATTERN))
    assert files, "Nu există fișiere de backup pentru a fi testate."
    latest = max(files, key=os.path.getctime)
    with open(latest, "r") as f:
        content = f.read().lower()
    keywords = ["cpu", "ram", "mem", "proces", "load", "uptime"]
    assert any(k in content for k in keywords), "Fișierul de backup nu conține date relevante despre sistem."