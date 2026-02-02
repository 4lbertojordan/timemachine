# Time Machine Samba Server

Docker-based Samba server optimized for macOS Time Machine backups. Provides a reliable and secure Time Machine destination for local network backups.

![GitHub release (latest by date)](https://img.shields.io/github/v/release/4lbertojordan/timemachine?style=flat-square&logo=github&color=blue)
![GitHub last commit](https://img.shields.io/github/last-commit/4lbertojordan/timemachine?style=flat-square)
![GitHub stars](https://img.shields.io/github/stars/4lbertojordan/timemachine?style=flat-square)
![GitHub issues](https://img.shields.io/github/issues/4lbertojordan/timemachine?style=flat-square)
![GitHub License](https://img.shields.io/github/license/4lbertojordan/timemachine?style=flat-square)

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
SMB_USER=backup_user
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

The server accepts connections only from:

- `127.0.0.1` (localhost)
- `192.168.153.0/24` (local network example - adjust to your network)
- `10.8.0.0/24` (VPN network example - adjust to your VPN)

To allow different networks, edit `smb_timemachine.conf`:

```conf
[global]
    hosts allow = 127.0.0.1 YOUR_NETWORK/24 YOUR_VPN_NETWORK/24
    hosts deny = ALL
```

## Docker Compose Usage

### Start the Server

```bash
docker compose -p timemachine -f docker-compose.yml up -d
```

### Stop the Server

```bash
docker compose -p timemachine -f docker-compose.yml down
```

### View Logs

```bash
docker compose -p timemachine -f docker-compose.yml logs -f
```

### Example docker-compose.yml

```yaml
services:
  timemachine:
    build:
      context: .
      dockerfile: timemachine.dockerfile
    container_name: timemachine
    restart: always
    env_file:
      - .env.timemachine
    ports:
      - "445:445"
    environment:
      - TZ=Europe/Madrid
    volumes:
      - ./timemachine/smb_timemachine.conf:/etc/samba/smb.conf:ro
      - ./timemachine/logs/log_tm:/var/log/samba
      - ./timemachine/:/timemachine
    deploy:
      resources:
        limits:
          memory: 1024M
```

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

**Reset user password:**

```bash
docker exec timemachine smbpasswd -a SMB_USER
```

### Slow Backups

- Check network connection (use wired ethernet if possible)
- Verify no other heavy network activity
- Check available disk space
- Consider increasing `memory` limit in docker-compose.yml

### Permission Errors

Ensure the timemachine directory has proper permissions:

```bash
# macOS host
ls -la ./timemachine/
# Should be owned by the user running Docker
```

## Network Recommendations

### Local Network Only (Most Secure)

Allow only your local network:

```conf
hosts allow = 127.0.0.1 192.168.1.0/24
hosts deny = ALL
```

### Add VPN Access

For remote access through VPN:

```conf
hosts allow = 127.0.0.1 192.168.1.0/24 10.8.0.0/24
hosts deny = ALL
```

### Do NOT Expose Directly to Internet

Time Machine shares should **never** be directly accessible from the internet. Always use:

- VPN for remote backups
- Firewall rules to limit access
- Local network only for best performance

## File Structure

```
.
├── docker-compose.yml           # Docker Compose configuration
├── timemachine.dockerfile       # Container image definition
├── entrypoint.sh                # Startup script
├── .env.timemachine            # Environment variables (not in git)
├── env.timemachine-example.txt  # Example environment variables
├── README.md                    # This file
├── CONTRIBUTING.md              # Contribution guidelines
├── SECURITY.md                  # Security policy
├── LICENSE                      # MIT License
└── timemachine/
    ├── smb_timemachine.conf     # Samba server configuration
    ├── logs/                    # Samba logs directory
    │   └── log_tm               # Time Machine share logs
    └── conf/                    # Additional configuration directory
```

## Performance Tuning

### Backup Speed

For faster backups, ensure:

1. **Wired Connection**: Use Ethernet for best performance
2. **Disk Speed**: Use SSD for backups (faster than HDD)
3. **Network Bandwidth**: 1Gbps or faster recommended
4. **Container Memory**: Increase limit if needed

```yaml
deploy:
  resources:
    limits:
      memory: 2048M # Increase from 1024M if needed
```

### Backup Size Limit

Edit `timemachine/smb_timemachine.conf` to change maximum backup size:

```conf
[TimeMachine]
    # Default: 850GB
    fruit:time machine max size = 1000000  # 1TB in MB
```

Remove the line entirely to use all available disk space.

## Security Considerations

### Best Practices

1. **Use Strong Passwords**: Minimum 12 characters, mixed case, numbers, symbols
2. **Restrict Network Access**: Limit `hosts allow` to trusted networks only
3. **VPN for Remote Access**: Never expose Samba directly to the internet
4. **Regular Updates**: Keep Docker image and host OS updated
5. **Monitor Logs**: Regularly check backup logs for errors

### Network Security

The server configuration restricts access by default:

```conf
hosts allow = 127.0.0.1 192.168.153.0/24 10.8.0.0/24
hosts deny = ALL
```

All other connections are rejected. Adjust these rules for your network.

### Data Protection

- Backups are stored in `/timemachine` volume
- Ensure proper file permissions on host
- Consider using encrypted storage volumes
- Implement regular backups of backups (backup rotation)

## macOS Exclusions

You can exclude folders from Time Machine backups:

1. Open **System Settings** → **General** → **Time Machine**
2. Click **Options**
3. Add folders to exclude list

Commonly excluded:

- Temporary files and caches
- Downloads folder (optional)
- Development build artifacts

## Monitoring Backups

### Check Backup Status on macOS

```bash
# Show latest backup
tmutil latestbackup

# List all backups
tmutil listbackups

# Check backup size
tmutil calculatedrift
```

### Monitor Server Logs

```bash
# Real-time logs
docker logs -f timemachine

# Specific log file
docker exec timemachine tail -f /var/log/samba/log.tm
```

## Backup Retention

Time Machine automatically manages backup retention:

- **Hourly backups**: Kept for 24 hours
- **Daily backups**: Kept for 1 month
- **Weekly backups**: Kept for all remaining backup size

Once the volume is full, oldest backups are deleted automatically.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security Reporting

Please report security vulnerabilities responsibly by following [SECURITY.md](SECURITY.md).

## License

MIT License - See [LICENSE](LICENSE) for details.
