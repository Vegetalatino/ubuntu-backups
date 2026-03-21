# Ubuntu Backup System

Sistema de backup híbrido para Ubuntu/Android (Termux + proot-distro)

## 📦 Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    SISTEMA HÍBRIDO                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  GitHub (este repo)          Google Drive               │
│  ├─ scripts/                 ├─ ubuntu-backups/         │
│  ├─ docs/                    │  ├─ ubuntu-full-*.tar.gz │
│  └─ config/                  │  └─ backup-*.tar.gz      │
│  (Scripts + Docs)            (Datos reales)             │
│                                                          │
│  Borg Local (incremental)                               │
│  └─ /root/borg-repo/                                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Características

- ✅ **Backup completo**: Archivos + lista de paquetes + script de restauración
- ✅ **Incremental**: Borg deduplica y comprime
- ✅ **Automático**: Cada noche a las 3:00 AM
- ✅ **Seguro**: Sin datos sensibles en GitHub
- ✅ **Flexible**: Restauración completa o parcial
- ✅ **Email**: Notificación automática
- ✅ **Sin límites**: Google Drive 2TB

## 📋 Requisitos

- Ubuntu/Debian en proot-distro (Termux)
- rclone configurado con Google Drive
- Borg Backup
- zstd
- Python 3

## 🔧 Instalación

### 1. Clonar repositorio

```bash
git clone https://github.com/Vegetalatino/ubuntu-backups.git
cd ubuntu-backups
```

### 2. Instalar dependencias

```bash
apt update
apt install -y borgbackup rclone zstd python3 python3-pip
```

### 3. Configurar rclone

```bash
rclone config
# Crear remote "gdrive" con Google Drive
```

### 4. Instalar scripts

```bash
cp scripts/*.sh /usr/local/bin/
chmod +x /usr/local/bin/backup-*.sh
```

### 5. Configurar credenciales

```bash
# Crear archivo de secrets
mkdir -p /root/.secrets
cat > /root/.secrets/.env << 'EOF'
GOOGLE_CLIENT_ID=tu_client_id
GOOGLE_CLIENT_SECRET=tu_client_secret
GOOGLE_REFRESH_TOKEN=tu_refresh_token
EOF

chmod 600 /root/.secrets/.env
```

### 6. Programar backup automático

```bash
echo "0 3 * * * /usr/local/bin/backup-full.sh" | crontab -
```

## 📖 Uso

### Backup completo manual

```bash
/usr/local/bin/backup-full.sh
```

### Restaurar desde Google Drive

```bash
/usr/local/bin/backup-restore.sh
```

### Verificar sistema

```bash
/usr/local/bin/backup-dry-run.sh
```

### Limpieza de emergencia

```bash
/usr/local/bin/backup-emergency-clean.sh
```

## 📊 Contenido del backup

| Incluido | Excluido |
|----------|----------|
| ✅ /etc (configuraciones) | ❌ /proc |
| ✅ /root (datos usuario) | ❌ /sys |
| ✅ /var (datos apps) | ❌ /dev |
| ✅ /usr/local/bin (scripts) | ❌ /tmp |
| ✅ Lista de paquetes | ❌ /var/cache |
| ✅ Repositorios APT | ❌ /var/log |
| ✅ Script de restauración | ❌ *.log |

## 🔄 Restauración completa

### En dispositivo nuevo:

1. **Instalar Termux + proot-distro + Ubuntu**

```bash
pkg install proot-distro
proot-distro install ubuntu
proot-distro login ubuntu
```

2. **Instalar dependencias**

```bash
apt update
apt install -y curl wget git rclone zstd
```

3. **Descargar backup**

```bash
rclone config  # Configurar gdrive
rclone copy gdrive:ubuntu-backups/ubuntu-full-*.tar.gz /tmp/
```

4. **Restaurar**

```bash
cd /tmp
tar -I 'zstd -d' -xf ubuntu-full-*.tar.gz
chmod +x restore.sh
./restore.sh
```

## 🛡️ Seguridad

- ❌ **NUNCA** subir secrets a GitHub
- ✅ Usar `.env` para credenciales
- ✅ Google Drive privado por defecto
- ✅ Backup encriptado (opcional con GPG)

## 📁 Estructura de archivos

```
/root/.openclaw/workspace/ubuntu-backups/
├── scripts/
│   ├── backup-full.sh           # Backup completo
│   ├── backup-restore.sh        # Restauración
│   └── backup-emergency-clean.sh # Limpieza
├── docs/
│   ├── RESTAURACION.md          # Guía detallada
│   └── TROUBLESHOOTING.md       # Solución de problemas
├── config/
│   ├── .env.example             # Template de secrets
│   └── crontab.example          # Template de cron
└── README.md                    # Este archivo
```

## 🔍 Monitoreo

- **Logs**: `/var/log/backup-full.log`
- **Email**: Confirmación automática
- **Google Drive**: Verificar archivos subidos
- **Borg local**: `borg list /root/borg-repo`

## 📈 Tamaño típico

- **Backup completo**: ~200-250 MB (comprimido)
- **Backup incremental**: ~50-100 MB
- **Retención**: 7 días, 4 semanas, 6 meses

## 🤝 Contribuir

1. Fork del repositorio
2. Crear rama: `git checkout -b feature/mejora`
3. Commit: `git commit -m 'Añadir mejora'`
4. Push: `git push origin feature/mejora`
5. Pull Request

## 📄 Licencia

MIT

## 👤 Autor

Vegetalatino

## 🔗 Enlaces

- [Repositorio](https://github.com/Vegetalatino/ubuntu-backups)
- [Issues](https://github.com/Vegetalatino/ubuntu-backups/issues)
- [Documentación completa](docs/RESTAURACION.md)
