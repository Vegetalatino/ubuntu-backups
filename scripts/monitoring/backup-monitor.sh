#!/bin/bash
# Monitor de backup - Verifica estado y envía reportes
# Se ejecuta cada 5 minutos

LOG_DIR="/var/log/backup"
STATUS_FILE="$LOG_DIR/backup.status"
LOG_FILE="$LOG_DIR/backup.log"
BACKUP_PID_FILE="/tmp/backup.pid"
EMAIL_SENT_FILE="$LOG_DIR/.email-sent-$(date +%Y%m%d)"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MONITOR] $1" >> "$LOG_FILE"
}

# ====== VERIFICAR BACKUP EN PROGRESO ======

if [ -f "$BACKUP_PID_FILE" ]; then
    PID=$(cat "$BACKUP_PID_FILE")
    
    if ps -p "$PID" > /dev/null 2>&1; then
        log "⏳ Backup en progreso (PID: $PID)"
        
        # Actualizar estado
        echo "STATUS=RUNNING" > "$STATUS_FILE"
        echo "PID=$PID" >> "$STATUS_FILE"
        echo "TIMESTAMP=$(date -Iseconds)" >> "$STATUS_FILE"
        
        # Verificar archivo en progreso
        CURRENT=$(ls -t /root/backup-temp/*.tar.gz 2>/dev/null | head -1)
        if [ -n "$CURRENT" ]; then
            SIZE=$(du -h "$CURRENT" | cut -f1)
            log "   Progreso: $(basename $CURRENT) ($SIZE)"
            echo "FILE=$(basename $CURRENT)" >> "$STATUS_FILE"
            echo "SIZE=$SIZE" >> "$STATUS_FILE"
        fi
        
        exit 0
    else
        log "✅ Backup terminó (PID $PID ya no existe)"
        rm -f "$BACKUP_PID_FILE"
    fi
fi

# ====== VERIFICAR BACKUP COMPLETADO ======

# Buscar backup más reciente en Drive
LATEST=$(rclone lsl gdrive:ubuntu-backups 2>/dev/null | grep "ubuntu-full" | tail -1)

if [ -n "$LATEST" ]; then
    BACKUP_DATE=$(echo "$LATEST" | awk '{print $2}')
    BACKUP_SIZE=$(echo "$LATEST" | awk '{print $1}')
    BACKUP_FILE=$(echo "$LATEST" | awk '{print $4}')
    
    TODAY=$(date +%Y-%m-%d)
    
    # Verificar si es de hoy
    if [[ "$BACKUP_DATE" == "$TODAY"* ]]; then
        log "✅ Backup de hoy encontrado: $BACKUP_FILE"
        
        # Actualizar estado
        echo "STATUS=COMPLETED" > "$STATUS_FILE"
        echo "FILE=$BACKUP_FILE" >> "$STATUS_FILE"
        echo "SIZE=$BACKUP_SIZE" >> "$STATUS_FILE"
        echo "TIMESTAMP=$(date -Iseconds)" >> "$STATUS_FILE"
        
        # Verificar si ya se envió email
        if [ ! -f "$EMAIL_SENT_FILE" ]; then
            log "📧 Enviando reporte de confirmación..."
            
            # Enviar email
            source /root/.secrets/.env 2>/dev/null
            
            TOKEN=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
                -d "client_id=${GOOGLE_CLIENT_ID}" \
                -d "client_secret=${GOOGLE_CLIENT_SECRET}" \
                -d "refresh_token=${REFRESH_TOKEN}" \
                -d "grant_type=refresh_token" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
            
            if [ -n "$TOKEN" ]; then
                # Formatear tamaño
                SIZE_GB=$(echo "scale=2; $BACKUP_SIZE / 1073741824" | bc 2>/dev/null || echo "$BACKUP_SIZE bytes")
                
                MSG="From: richardperes070797@gmail.com
To: richardperes070797@gmail.com
Subject: [OK] Backup Ubuntu - $TODAY
MIME-Version: 1.0
Content-Type: text/plain; charset=\"UTF-8\"

✅ Backup de Ubuntu completado exitosamente

Detalles:
- Fecha: $BACKUP_DATE
- Archivo: $BACKUP_FILE
- Tamaño: ${SIZE_GB} GB
- Ubicación: Google Drive / ubuntu-backups

---
OpenClaw Backup Monitor"
                
                RAW=$(echo "$MSG" | base64 -w 0 | sed 's/+/-/g; s/\//_/g')
                
                RESPONSE=$(curl -s -X POST \
                    "https://gmail.googleapis.com/gmail/v1/users/me/messages/send" \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/json" \
                    -d "{\"raw\":\"$RAW\"}")
                
                if echo "$RESPONSE" | grep -q '"id"'; then
                    EMAIL_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
                    log "✅ Email enviado: $EMAIL_ID"
                    touch "$EMAIL_SENT_FILE"
                    
                    # ====== LIMPIAR LOGS DESPUÉS DE ENVIAR EMAIL ======
                    log "🧹 Limpiando logs antiguos..."
                    
                    # Mantener solo últimos 100 líneas del log principal
                    tail -100 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null
                    mv "$LOG_FILE.tmp" "$LOG_FILE" 2>/dev/null
                    
                    # Limpiar logs antiguos (más de 7 días)
                    find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null
                    find "$LOG_DIR" -name ".email-sent-*" -mtime +7 -delete 2>/dev/null
                    
                    # Limpiar archivos temporales de backup
                    rm -rf /root/backup-temp/*.tar.gz 2>/dev/null
                    rm -f /tmp/packages.txt /tmp/apt-backup /tmp/apt-backup-lib /tmp/restore.sh 2>/dev/null
                    
                    log "✅ Logs limpiados"
                else
                    log "❌ Error enviando email: $RESPONSE"
                fi
            else
                log "❌ Error: Sin token de acceso"
            fi
        else
            log "ℹ️ Email ya enviado hoy"
        fi
    else
        log "ℹ️ Último backup es de: $BACKUP_DATE"
        echo "STATUS=OLD" > "$STATUS_FILE"
        echo "LAST_DATE=$BACKUP_DATE" >> "$STATUS_FILE"
    fi
else
    log "⚠️ No se encontraron backups en Drive"
    echo "STATUS=NO_BACKUP" > "$STATUS_FILE"
fi
