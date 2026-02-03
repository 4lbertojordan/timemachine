# Time Machine Samba Server

A simple Docker-based Samba server optimized for macOS Time Machine backups. Provides a reliable and secure Time Machine destination for local network backups.

![GitHub release (latest by date)](https://img.shields.io/github/v/release/4lbertojordan/timemachine?style=flat-square&logo=github&color=blue)
![GitHub last commit](https://img.shields.io/github/last-commit/4lbertojordan/timemachine?style=flat-square)
![GitHub stars](https://img.shields.io/github/stars/4lbertojordan/timemachine?style=flat-square)
![GitHub issues](https://img.shields.io/github/issues/4lbertojordan/timemachine?style=flat-square)
![GitHub License](https://img.shields.io/github/license/4lbertojordan/timemachine?style=flat-square)

![Docker Image Version](https://img.shields.io/docker/v/jord4ncodes/timemachine?sort=semver&style=flat-square&logo=docker)
![Docker Pulls](https://img.shields.io/docker/pulls/jord4ncodes/timemachine?style=flat-square&logo=docker)
![Docker Image Size](https://img.shields.io/docker/image-size/jord4ncodes/timemachine/latest?style=flat-square&logo=docker)

## Features

- Debian-based lightweight image
- Samba 4 with SMB2/SMB3 protocol support
- Apple Time Machine optimized configuration
- User/password authentication
- Healthcheck included
- Multi-architecture support (amd64, arm64)

## Requirements

- Docker and Docker Compose installed
- Port 445/tcp available
- ARM64 or x86-64 architecture
- Host storage for Time Machine backups (I recommend using an external drive or NAS isolated from the OS)

## Supported macOS Versions

Time Machine backups are compatible with MacOS:

- Tested and working on macOS Tahoe 26.2 (25C56)

## Quick Start

### 1. Create Environment File and Set Permissions

Create `.env.timemachine` in your repository root:

```dotenv
# Samba user and password
SMB_USER=backup_user_here
SMB_PASSWORD=your_secure_password_here
SMB_UID=1000
SMB_GROUP=home
SMB_GID=1000

# Container timezone
TZ=Europe/Madrid
```

Set permission for time machine directory:

```bash
mkdir -p ./timemachine
chown 1000:1000 ./timemachine && chmod 700 ./timemachine
```

### 2. Launch the Container

```bash
docker compose -p timemachine -f docker-compose.yml up -d
```

### 3. Configure Time Machine on macOS

This Time Machine share is automatically discovered using Avahi (Bonjour) if not please follow these steps:

1. Open your terminal and run:

   ```bash
   sudo tmutil setdestination -p "smb://jordancodes@YOUR_SERVER_IP/TimeMachine"
   ```

2. Enter your Samba password when prompted.
3. Open **System Settings** → **General** → **Time Machine** and ensure the Time Machine share is selected.
4. Start your first backup!

## Configuration

### Environment Variables

| Variable       | Description                                         | Example         | Default     |
| -------------- | --------------------------------------------------- | --------------- | ----------- |
| `SMB_USER`     | Samba username for Time Machine backups             | `backup_user`   | jordancodes |
| `SMB_PASSWORD` | Samba password (leave empty to skip password setup) | `secure_pass`   | (empty)     |
| `SMB_UID`      | Linux user ID for the Samba user                    | `1000`          | 1000        |
| `SMB_GROUP`    | Linux group for the Samba user                      | `home`          | home        |
| `SMB_GID`      | Linux group ID for the Samba group                  | `1000`          | 1000        |
| `TZ`           | Container timezone (for log timestamps)             | `Europe/Madrid` | UTC         |

### Samba Configuration

The server configuration is defined in [timemachine/smb_timemachine.conf](timemachine/smb_timemachine.conf).

**Key Settings:**

- **Time Machine Volume**: `/timemachine` (inside container)
- **Share Name**: `[TimeMachine]`
- **Protocol**: SMB2/SMB3
- **Security Model**: User authentication required
- **Mac Optimization**: Enabled with `fruit:time machine = yes`
- **Max Backup Size**: 850GB (configurable)

**Network Security:**

I recommend allowing only trusted networks:

- `127.0.0.1` (localhost)
- `192.168.XXX.0/24` (local network example - adjust to your network)
- `10.8.0.0/24` (VPN network example - adjust to your VPN)

## Troubleshooting

### Cannot Connect from macOS

**Check if Samba is running:**

```bash
docker compose -p timemachine -f docker-compose.yml ps
```

**Verify port is listening:**

```bash
netstat -an | grep 445
```

**Check Samba logs:**

```bash
docker logs timemachine
```

### Authentication Issues

Ensure credentials match `.env.timemachine`:

- Username must match `SMB_USER`
- Password must match `SMB_PASSWORD`

### Slow Backups

- Check network connection (use wired ethernet if possible)
- Verify no other heavy network activity
- Check available disk space
- Consider increasing `memory` limit in docker-compose.yml

### Permission Errors

Ensure the timemachine directory has proper permissions:

```bash
# linux host
ls -la ./timemachine/
# Should be owned by the user running Docker
```

## macOS Exclusions

You can exclude folders from Time Machine backups:

1. Open **System Settings** → **General** → **Time Machine**
2. Click **Options**
3. Add folders to exclude list

## Monitoring Backups

### Check Backup Status on macOS

NOTE: I detect that `tmutil` commands may require some time to reflect any information.

```bash
# Show latest backup
tmutil latestbackup

# List all backups
tmutil listbackups

# Check backup size
tmutil calculatedrift
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security Reporting

Please report security vulnerabilities responsibly by following [SECURITY.md](SECURITY.md).

## License

MIT License - See [LICENSE](LICENSE) for details.
