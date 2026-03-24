#!/bin/bash
# Daemon principal - Se ejecuta continuamente
# Verifica cada 5 minutos si debe ejecutar backup o enviar reporte

LOG_DIR="/var/log/backup"
LOG_FILE="$LOG_DIR/daemon.log"
CHECK_INTERVAL=300  # 5 minutos

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "🦞 Daemon de backup iniciado"
log "Intervalo de verificación: ${CHECK_INTERVAL}s"

while true; do
    # Ejecutar monitor
    /usr/local/bin/backup-monitor.sh >> "$LOG_FILE" 2>&1
    
    # Ejecutar daemon de backup (verificará si es hora)
    /usr/local/bin/backup-daemon-logged.sh >> "$LOG_FILE" 2>&1
    
    # Esperar
    sleep $CHECK_INTERVAL
done
