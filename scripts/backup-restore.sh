#!/bin/bash
# Script de restauración desde Google Drive
# Uso: backup-restore.sh [fecha]
# Ejemplo: backup-restore.sh 20260321

set -e

DATE=${1:-$(date +%Y%m%d)}
HOSTNAME=$(hostname)
BACKUP_DIR="/tmp/restore-$$"

echo "=== RESTAURACIÓN DE UBUNTU ==="
echo ""
echo "Buscando backup del día: $DATE"
echo ""

# Verificar rclone
if ! rclone listremotes | grep -q "gdrive:"; then
    echo "ERROR: rclone no está configurado con Google Drive"
    echo "Ejecuta: rclone config"
    exit 1
fi

# Buscar backup
echo "Buscando backups disponibles..."
rclone lsl gdrive:ubuntu-backups | grep "ubuntu-full" | tail -10

echo ""
echo "Descargando backup más reciente..."
BACKUP_FILE=$(rclone lsl gdrive:ubuntu-backups | grep "ubuntu-full" | tail -1 | awk '{print $NF}')

if [ -z "$BACKUP_FILE" ]; then
    echo "ERROR: No se encontró backup"
    exit 1
fi

echo "Encontrado: $BACKUP_FILE"
echo ""

# Crear directorio temporal
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# Descargar
echo "Descargando..."
rclone copy "gdrive:ubuntu-backups/$BACKUP_FILE" . --progress

# Extraer
echo ""
echo "Extrayendo backup..."
tar -I 'zstd -d' -xf "$BACKUP_FILE"

# Verificar que existe el script de restauración
if [ ! -f "restore.sh" ]; then
    echo "ERROR: El backup no contiene script de restauración"
    exit 1
fi

echo ""
echo "=========================================="
echo "ARCHIVOS LISTOS PARA RESTAURAR"
echo "=========================================="
echo ""
echo "Ubicación: $BACKUP_DIR"
echo ""
ls -lh "$BACKUP_DIR"
echo ""
echo "Para completar la restauración:"
echo "  cd $BACKUP_DIR"
echo "  chmod +x restore.sh"
echo "  ./restore.sh"
echo ""
echo "O restaurar manualmente:"
echo "  1. Revisar packages.txt"
echo "  2. Restaurar archivos: tar -xzf backup-data.tar.gz -C /"
echo ""
