#!/bin/bash
# Backup COMPLETO de Ubuntu para restauración en otro dispositivo
# Incluye lista de paquetes y configuración completa

set -e

DATE=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)
BACKUP_DIR="/root/backup-temp"
BACKUP_FILE="${BACKUP_DIR}/ubuntu-full-${HOSTNAME}-${DATE}.tar.gz"
LOG="/var/log/backup-full.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

log "=========================================="
log "Backup COMPLETO de Ubuntu"
log "=========================================="

# Crear directorio temporal
mkdir -p "$BACKUP_DIR"

# 1. Lista de paquetes instalados
log "Generando lista de paquetes..."
dpkg --get-selections > /tmp/packages.txt 2>/dev/null

# 2. Repositorios y claves APT
log "Exportando repositorios APT..."
cp -r /etc/apt /tmp/apt-backup 2>/dev/null
cp -r /var/lib/apt /tmp/apt-backup-lib 2>/dev/null

# 3. Crear archivo de restauración
log "Creando script de restauración..."
cat > /tmp/restore.sh << 'RESTOREOF'
#!/bin/bash
# Script de restauración automática
# Ejecutar como root en el nuevo dispositivo

set -e

echo "=== RESTAURACIÓN DE UBUNTU ==="
echo ""

# Verificar que estamos en Ubuntu/Debian
if [ ! -f /etc/debian_version ] && [ ! -f /etc/ubuntu-release ]; then
    echo "ERROR: Este script es solo para Ubuntu/Debian"
    exit 1
fi

# 1. Restaurar repositorios APT
echo "1. Restaurando repositorios APT..."
if [ -d apt-backup ]; then
    cp -r apt-backup/* /etc/apt/ 2>/dev/null || true
    cp -r apt-backup-lib/* /var/lib/apt/ 2>/dev/null || true
fi

# 2. Actualizar e instalar paquetes
echo "2. Actualizando lista de paquetes..."
apt update 2>/dev/null || true

echo "3. Instalando paquetes desde lista..."
if [ -f packages.txt ]; then
    # Filtrar líneas vacías y comentarios
    grep -v '^#' packages.txt | grep -v '^$' | while read pkg status; do
        pkg_name=$(echo "$pkg" | awk '{print $1}')
        if [ -n "$pkg_name" ] && [ "$status" = "install" ]; then
            echo "Instalando: $pkg_name"
            apt install -y "$pkg_name" 2>/dev/null || echo "No se pudo instalar: $pkg_name"
        fi
    done
fi

# 3. Restaurar archivos de configuración y datos
echo "4. Restaurando archivos..."
if [ -f backup-data.tar.gz ]; then
    tar -xzf backup-data.tar.gz -C / 2>/dev/null || echo "Algunos archivos no se pudieron restaurar"
fi

# 4. Reinstalar paquetes OpenClaw
echo "5. Reinstalando OpenClaw..."
if command -v npm &>/dev/null; then
    npm install -g openclaw 2>/dev/null || echo "OpenClaw ya está instalado o use npm install -g openclaw"
fi

# 5. Reinstalar otros paquetes globales
echo "6. Reinstalando herramientas..."
npm install -g n8n 2>/dev/null || true
npm install -g rclone 2>/dev/null || true
npm install -g borgbackup 2>/dev/null || true

# 6. Verificar servicios
echo "7. Verificando servicios..."
systemctl daemon-reload 2>/dev/null || true

echo ""
echo "=== RESTAURACIÓN COMPLETADA ==="
echo ""
echo "Pasos manuales recomendados:"
echo "1. Revisar /etc/hosts y /etc/hostname"
echo "2. Reiniciar servicios: systemctl restart openclaw n8n"
echo "3. Verificar claves SSH en ~/.ssh/"
echo "4. Reautenticar rclone: rclone config"
echo "5. Revisar permisos: chmod 600 ~/.secrets/.env"
RESTOREOF

# 4. Crear backup completo con zstd
log "Creando backup completo..."
tar -I 'zstd -19 -T0' -cf "$BACKUP_FILE" \
    --exclude='/proc' \
    --exclude='/sys' \
    --exclude='/dev' \
    --exclude='/tmp' \
    --exclude='/run' \
    --exclude='/mnt' \
    --exclude='/media' \
    --exclude='/var/cache' \
    --exclude='/var/tmp' \
    --exclude='/var/backups' \
    --exclude='/root/backup-temp' \
    --exclude='/root/borg-repo' \
    --exclude='*.log' \
    -C /tmp \
    packages.txt \
    apt-backup \
    apt-backup-lib \
    restore.sh \
    -C / \
    etc \
    root \
    var \
    usr/local/bin \
    usr/local/sbin \
    2>&1 | tee -a "$LOG"

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
log "Backup creado: $BACKUP_FILE ($BACKUP_SIZE)"

# 5. Subir a Google Drive
log "Subiendo a Google Drive..."
rclone copy "$BACKUP_FILE" gdrive:ubuntu-backups --progress 2>&1 | tee -a "$LOG"

# 6. Verificar
if rclone ls gdrive:ubuntu-backups/$(basename "$BACKUP_FILE") 2>/dev/null; then
    log "✅ Backup subido exitosamente"
else
    log "❌ ERROR: No se pudo verificar la subida"
    exit 1
fi

# 7. Limpiar
rm -rf /tmp/packages.txt /tmp/apt-backup /tmp/apt-backup-lib /tmp/restore.sh
rm -f "$BACKUP_FILE"
log "Archivos temporales eliminados"

# 8. Resumen
log "=========================================="
log "Backup COMPLETO finalizado"
log "=========================================="
log ""
log "Incluye:"
log "- Lista de paquetes (packages.txt)"
log "- Repositorios APT"
log "- Script de restauración (restore.sh)"
log "- Archivos del sistema"
log ""
log "Para restaurar en otro dispositivo:"
log "1. rclone copy gdrive:ubuntu-backups/$(basename $BACKUP_FILE) /tmp/"
log "2. cd /tmp && tar -I 'zstd -d' -xf $(basename $BACKUP_FILE)"
log "3. chmod +x restore.sh && ./restore.sh"
log ""
log "Tamaño: $BACKUP_SIZE"
