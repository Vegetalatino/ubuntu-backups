# Solución de Problemas Comunes

## ❌ Error: "rclone: command not found"

**Solución:**
```bash
apt install -y rclone
```

---

## ❌ Error: "Google Drive remote 'gdrive' not configured"

**Solución:**
```bash
rclone config
# Seguir el asistente interactivo
```

---

## ❌ Error: "Borg backup failed"

**Solución:**
```bash
# Verificar espacio disponible
df -h / | tail -1

# Verificar repositorio Borg
borg list /root/borg-repo

# Si está corrupto
borg check --repair /root/borg-repo
```

---

## ❌ Error: "No space left on device"

**Solución:**
```bash
# Ejecutar limpieza de emergencia
/usr/local/bin/backup-emergency-clean.sh

# Verificar backups en Drive y eliminar los más antiguos
rclone lsl gdrive:ubuntu-backups
rclone delete gdrive:ubuntu-backups/archivo-antiguo.tar.gz
```

---

## ❌ Error: "Email notification failed"

**Solución:**
```bash
# Verificar configuración de Gmail
source /root/.secrets/.env

# Verificar que las variables están definidas
echo $GOOGLE_CLIENT_ID
echo $GOOGLE_CLIENT_SECRET
echo $GOOGLE_REFRESH_TOKEN

# Si falta alguna, obtener nuevos tokens desde Google Cloud Console
```

---

## ❌ Error: "Cron job not running"

**Solución:**
```bash
# Verificar que el cron job existe
crontab -l

# Verificar logs del sistema
tail -f /var/log/syslog | grep CRON

# Verificar que el servicio cron está corriendo
systemctl status cron 2>/dev/null || service cron status 2>/dev/null
```

---

## ❌ Error: "Restore failed - archive corrupted"

**Solución:**
```bash
# Verificar integridad del archivo
rclone md5sum gdrive:ubuntu-backups/archivo.tar.gz

# Si está corrupto, descargar de nuevo
rclone copy gdrive:ubuntu-backups/archivo.tar.gz /tmp/

# Verificar con Borg
borg check --verify-data /root/borg-repo
```

---

## 📞 Logs útiles

```bash
# Ver logs de backup
tail -f /var/log/backup-full.log

# Ver logs del sistema
journalctl -u backup -f

# Ver actividad reciente
last | head -20 /var/log/backup-full.log
```

---

## 🔄 Restauración de emergencia

```bash
# Si el sistema no arranca, restaurar desde el último backup
rclone copy gdrive:ubuntu-backups/ubuntu-full-*.tar.gz /tmp/
cd /tmp
tar -I 'zstd -d' -xf ubuntu-full-*.tar.gz
chmod +x restore.sh
./restore.sh
```
