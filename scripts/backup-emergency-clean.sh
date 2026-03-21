#!/bin/bash
# Script de limpieza de emergencia si los backups llenan el disco

echo "=== LIMPIEZA DE EMERGENCIA DE BACKUPS ==="
echo ""

# 1. Limpiar backups antiguos en /var/backups
echo "1. Limpiando /var/backups..."
BACKUP_SIZE=$(du -sh /var/backups 2>/dev/null | cut -f1)
echo "   Tamaño actual: $BACKUP_SIZE"
find /var/backups -name "*.tar.gz" -mtime +3 -delete 2>/dev/null
echo "   ✅ Backups de más de 3 días eliminados"

# 2. Limpiar repositorio Borg antiguo
echo ""
echo "2. Verificando repositorio Borg..."
if [ -d "/root/borg-repo" ]; then
    BORG_SIZE=$(du -sh /root/borg-repo 2>/dev/null | cut -f1)
    echo "   Tamaño actual: $BORG_SIZE"
    borg prune /root/borg-repo --keep-daily=3 --keep-weekly=1 --keep-monthly=1
    borg compact /root/borg-repo
    echo "   ✅ Repositorio optimizado"
fi

# 3. Limpiar archivos temporales de backup
echo ""
echo "3. Limpiando archivos temporales..."
rm -rf /tmp/backups/* 2>/dev/null
rm -rf /root/backups-temp/* 2>/dev/null
rm -f /tmp/ubuntu-*.tar.gz 2>/dev/null
rm -f /tmp/email_* 2>/dev/null
echo "   ✅ Archivos temporales eliminados"

# 4. Limpiar logs antiguos
echo ""
echo "4. Limpiando logs antiguos..."
find /var/log -name "*.log" -mtime +7 -delete 2>/dev/null
find /var/log -name "*.gz" -mtime +7 -delete 2>/dev/null
truncate -s 0 /var/log/backup-ubuntu.log 2>/dev/null
echo "   ✅ Logs antiguos eliminados"

# 5. Mostrar espacio recuperado
echo ""
echo "=== ESPACIO LIBRE ACTUAL ==="
df -h /

echo ""
echo "✅ LIMPIEZA COMPLETADA"
