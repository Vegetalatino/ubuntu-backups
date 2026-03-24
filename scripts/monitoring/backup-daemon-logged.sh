#!/bin/bash
# Daemon de backup con logging completo
# Ejecuta backup a las 3:00 AM y monitorea progreso

LOG_DIR="/var/log/backup"
LOG_FILE="$LOG_DIR/backup.log"
BACKUP_PID_FILE="/tmp/backup.pid"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Verificar si es hora (3:00-3:59 AM)
HOUR=$(date +%H)
TODAY=$(date +%Y%m%d)
LAST_RUN="/tmp/.backup-run-$TODAY"

if [ "$HOUR" -eq 3 ] && [ ! -f "$LAST_RUN" ]; then
    log "=========================================="
    log "🌙 INICIANDO BACKUP DIARIO"
    log "=========================================="
    
    # Marcar como iniciado
    touch "$LAST_RUN"
    
    # Registrar PID
    echo $$ > "$BACKUP_PID_FILE"
    
    # Ejecutar backup
    log "▶️ Ejecutando backup..."
    
    /usr/local/bin/backup-full.sh 2>&1 | while read line; do
        log "  $line"
    done
    
    BACKUP_EXIT=${PIPESTATUS[0]}
    
    if [ $BACKUP_EXIT -eq 0 ]; then
        log "✅ Backup completado exitosamente"
        
        # Obtener info del backup
        LATEST=$(ls -t /root/backup-temp/*.tar.gz 2>/dev/null | head -1)
        if [ -n "$LATEST" ]; then
            SIZE=$(du -h "$LATEST" | cut -f1)
            log "📦 Archivo: $(basename $LATEST) ($SIZE)"
            
            # Subir a Drive
            log "☁️ Subiendo a Google Drive..."
            rclone copy "$LATEST" gdrive:ubuntu-backups --progress 2>&1 | while read line; do
                log "  $line"
            done
            
            if [ $? -eq 0 ]; then
                log "✅ Subida completada"
                
                # Eliminar archivo local
                rm -f "$LATEST"
                log "🗑️ Archivo temporal eliminado"
            else
                log "❌ Error subiendo a Drive"
            fi
        fi
    else
        log "❌ Error en backup (código: $BACKUP_EXIT)"
    fi
    
    # Limpiar PID
    rm -f "$BACKUP_PID_FILE"
    
    log "=========================================="
    log "🌙 BACKUP FINALIZADO"
    log "=========================================="
fi
