# Sistema de Monitoreo de Backup

## 📊 Descripción General

El sistema de monitoreo verifica automáticamente el estado del backup y envía reportes por email cuando se completa.

## 🔄 Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                SISTEMA DE MONITOREO                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  backup-main-daemon.sh (continuo)                       │
│  └─ Cada 5 minutos:                                     │
│     ├─ backup-monitor.sh (verifica estado)              │
│     │  ├─ Detecta backup en progreso                    │
│     │  ├─ Detecta backup completado                     │
│     │  └─ Envía email si terminó                        │
│     └─ backup-daemon-logged.sh (ejecuta a las 3 AM)     │
│        └─ backup-full.sh (backup real)                  │
│                                                          │
│  Logs: /var/log/backup/                                 │
│  └─ backup.log (principal)                              │
│  └─ backup.status (estado actual)                       │
│  └─ daemon.log (daemon)                                 │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Instalación

```bash
# Crear directorio de logs
mkdir -p /var/log/backup

# Instalar scripts de monitoreo
cp scripts/monitoring/*.sh /usr/local/bin/
cp scripts/monitoring/estado-backup /usr/local/bin/
cp scripts/monitoring/enviar-reporte-backup /usr/local/bin/

# Dar permisos
chmod +x /usr/local/bin/backup-*.sh
chmod +x /usr/local/bin/estado-backup
chmod +x /usr/local/bin/enviar-reporte-backup

# Iniciar daemon
nohup /usr/local/bin/backup-main-daemon.sh > /dev/null 2>&1 &
echo $! > /tmp/backup-daemon.pid
```

## 📋 Comandos Disponibles

### Ver estado del backup

```bash
estado-backup
```

Muestra:
- Estado actual (RUNNING/COMPLETED/ERROR)
- Últimos backups en Google Drive
- Si el email fue enviado
- Si el daemon está activo

### Enviar reporte manualmente

```bash
enviar-reporte-backup
```

Envía email con el último backup encontrado en Google Drive.

### Ver logs en tiempo real

```bash
tail -f /var/log/backup/backup.log
```

### Ver estado actual

```bash
cat /var/log/backup/backup.status
```

## 📧 Email Automático

### Cuándo se envía

- ✅ Backup completado exitosamente
- ✅ Archivo subido a Google Drive
- ✅ Email no enviado hoy

### Contenido del email

```
✅ Backup de Ubuntu completado exitosamente

Detalles:
- Fecha: 2026-03-24 03:37:49
- Archivo: ubuntu-full-localhost-20260324_032331.tar.gz
- Tamaño: 3.62 GB
- Ubicación: Google Drive / ubuntu-backups

---
OpenClaw Backup Monitor
```

## 🧹 Limpieza de Logs

### Automática

Después de enviar el email:
- ✅ Mantiene últimas 100 líneas del log principal
- ✅ Elimina logs de más de 7 días
- ✅ Elimina archivos temporales de backup
- ✅ Elimina marcas de email antiguas

### Manual

```bash
# Limpiar logs manualmente
find /var/log/backup -name "*.log" -mtime +7 -delete

# Limpiar temporales
rm -rf /root/backup-temp/*.tar.gz
```

## 📊 Estados del Sistema

| Estado | Descripción |
|--------|-------------|
| `RUNNING` | Backup en progreso |
| `COMPLETED` | Backup completado y subido |
| `OLD` | Último backup es de fecha anterior |
| `NO_BACKUP` | No hay backups en Drive |
| `ERROR` | Error en el backup |

## 🔍 Verificación de Salud

### Daemon activo

```bash
ps aux | grep backup-main-daemon
```

### Último backup

```bash
rclone lsl gdrive:ubuntu-backups | tail -5
```

### Logs recientes

```bash
tail -20 /var/log/backup/backup.log
```

## 🛠️ Troubleshooting

### Daemon no corre

```bash
# Verificar si está activo
ps aux | grep backup-main-daemon

# Si no está, iniciarlo
nohup /usr/local/bin/backup-main-daemon.sh > /dev/null 2>&1 &
echo $! > /tmp/backup-daemon.pid
```

### Email no se envía

1. Verificar credenciales en `/root/.secrets/.env`
2. Verificar token de Google OAuth
3. Verificar logs: `tail -f /var/log/backup/backup.log`

### Logs muy grandes

```bash
# Limpiar manualmente
> /var/log/backup/backup.log
> /var/log/backup/daemon.log
```

## 📈 Monitoreo Proactivo

### Verificar cada hora

El sistema automáticamente:
1. Verifica si hay backup en progreso
2. Detecta cuando termina
3. Envía email si es necesario
4. Limpia logs automáticamente

### Alertas

- ✅ Email de confirmación cuando termina
- ✅ Logs detallados para troubleshooting
- ✅ Estado persistente en `/var/log/backup/backup.status`

## 🔒 Seguridad

- ✅ Logs no contienen datos sensibles
- ✅ Credenciales en `/root/.secrets/.env` (permisos 600)
- ✅ Limpieza automática de temporales
- ✅ Sin información sensible en Google Drive

## 📅 Mantenimiento

### Diario

- ✅ Automático: Backup a las 3 AM
- ✅ Automático: Email de confirmación
- ✅ Automático: Limpieza de logs

### Semanal

```bash
# Verificar estado general
estado-backup

# Verificar espacio en Drive
rclone about gdrive
```

### Mensual

```bash
# Verificar backups antiguos
rclone lsl gdrive:ubuntu-backups | head -20

# Limpiar backups muy antiguos si es necesario
rclone delete gdrive:ubuntu-backups --min-age 180d
```

## 📝 Notas

- El daemon se ejecuta continuamente en segundo plano
- Verifica cada 5 minutos si debe hacer algo
- Los logs se limpian automáticamente después del email
- El sistema es resistente a reinicios (usa archivos de estado)
