# Guía de Restauración Completa

## 🔄 Restauración en nuevo dispositivo

### Prerrequisitos

- Termux instalado en Android
- Conexión a internet
- Cuenta de Google con acceso a Drive

---

## Paso 1: Preparar el nuevo dispositivo

### 1.1 Instalar Termux

```bash
# Descargar Termux de F-Droid o Play Store
# https://f-droid.org/packages/com.termux/
```

### 1.2 Actualizar Termux

```bash
pkg update && pkg upgrade
```

### 1.3 Instalar proot-distro

```bash
pkg install proot-distro
```

### 1.4 Instalar Ubuntu

```bash
proot-distro install ubuntu
proot-distro login ubuntu
```

---

## Paso 2: Clonar repositorio de scripts

### 2.1 Instalar dependencias

```bash
apt update
apt install -y git curl wget
```

### 2.2 Clonar repositorio

```bash
cd /tmp
git clone https://github.com/Vegetalatino/ubuntu-backups.git
cd ubuntu-backups
```

### 2.3 Instalar scripts

```bash
cp scripts/* /usr/local/bin/
chmod +x /usr/local/bin/backup-*.sh
```

---

## Paso 3: Configurar rclone

### 3.1 Instalar rclone

```bash
apt install -y rclone
```

### 3.2 Configurar Google Drive

```bash
rclone config
```

Seguir el asistente:
1. `n` - nuevo remote
2. Nombre: `gdrive`
3. Storage: `drive` (Google Drive)
4. client_id: (Enter para vacío)
5. client_secret: (Enter para vacío)
6. scope: `1` (Full access)
7. root_folder_id: (Enter)
8. service_account_file: (Enter)
9. advanced_config: `n`
10. **Se abrirá navegador para autorizar**
11. auto_confirm: `n` o `y`
12. `y` - confirmar
13. `q` - salir

---

## Paso 4: Descargar backup

### 4.1 Ver backups disponibles

```bash
rclone lsl gdrive:ubuntu-backups
```

### 4.2 Descargar el más reciente

```bash
rclone copy gdrive:ubuntu-backups/ubuntu-full-*.tar.gz /tmp/
```

---

## Paso 5: Restaurar

### 5.1 Extraer backup

```bash
cd /tmp
tar -I 'zstd -d' -xf ubuntu-full-*.tar.gz
```

### 5.2 Ejecutar script de restauración

```bash
chmod +x restore.sh
./restore.sh
```

### 5.3 Verificar restauración

```bash
# Verificar que los archivos están en su lugar
ls -la /root/.openclaw/
ls -la /usr/local/bin/backup-*.sh

# Verificar servicios
systemctl status openclaw 2>/dev/null || echo "OpenClaw no instalado como servicio"
```

---

## Paso 6: Configurar servicios

### 6.1 Instalar OpenClaw

```bash
npm install -g openclaw
```

### 6.2 Configurar OpenClaw

```bash
# Copiar configuración
cp -r config/openclaw/* /root/.openclaw/

# Configurar secrets
cp config/.env.example /root/.secrets/.env
nano /root/.secrets/.env  # Editar con tus claves reales
```

### 6.3 Iniciar servicios

```bash
# Iniciar OpenClaw
openclaw gateway start

# Iniciar n8n
n8n start --port=5678
```

---

## Paso 7: Configurar backups automáticos

### 7.1 Configurar cron

```bash
# Copiar configuración de cron
cp config/crontab.example /etc/cron.d/backup-ubuntu

# Verificar que está programado
crontab -l
```

### 7.2 Verificar backups

```bash
# Verificar que el backup se ejecutó
tail -f /var/log/backup-full.log
```

---

## 🔧 Restauración Parcial

Si solo necesitas restaurar archivos específicos:

### Restaurar solo configuraciones

```bash
rclone copy gdrive:ubuntu-backups/ubuntu-full-*.tar.gz /tmp/
cd /tmp
tar -I 'zstd -d' -xf ubuntu-full-*.tar.gz
tar -xzf backup-data.tar.gz -C / etc/
```

### Restaurar solo datos de usuario

```bash
tar -xzf backup-data.tar.gz -C / root/
```

### Restaurar solo scripts

```bash
tar -xzf backup-data.tar.gz -C / usr/local/bin/
```

---

## 🆘 Solución de Problemas

### Error: "No space left on device"

```bash
# Limpiar archivos temporales
/usr/local/bin/backup-emergency-clean.sh
```

### Error: "rclone: command not found"

```bash
apt install -y rclone
```

### Error: "Permission denied"

```bash
chmod +x /usr/local/bin/backup-*.sh
```

### Error: "zstd: command not found"

```bash
apt install -y zstd
```

---

## 📞 Soporte

Si tienes problemas:
1. Revisar logs: `/var/log/backup-full.log`
2. Verificar espacio: `df -h`
3. Verificar rclone: `rclone config show`
4. Crear issue: https://github.com/Vegetalatino/ubuntu-backups/issues

---

## ✅ Verificación Final

Después de la restauración, verificar:

```bash
# 1. Espacio en disco
df -h

# 2. Servicios corriendo
ps aux | grep -E "openclaw|n8n"

# 3. Backups configurados
crontab -l

# 4. Último backup
rclone lsl gdrive:ubuntu-backups | tail -1

# 5. Scripts disponibles
ls -la /usr/local/bin/backup-*.sh
```

---

**¡Restauración completada!** 🎉
