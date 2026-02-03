#!/bin/bash
set -e

[ -n "$TZ" ] && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

USER_NAME=${SMB_USER:-jordan}
USER_UID=${SMB_UID:-1000}
GROUP_NAME=${SMB_GROUP:-home}
GROUP_GID=${SMB_GID:-1000}

getent group "$GROUP_NAME" >/dev/null || groupadd -g "$GROUP_GID" "$GROUP_NAME"
id -u "$USER_NAME" >/dev/null 2>&1 || useradd -u "$USER_UID" -g "$GROUP_GID" -M -s /sbin/nologin "$USER_NAME"

mkdir -p /var/lib/samba/private /var/log/samba /var/run/samba
chmod 700 /var/lib/samba/private


if [ -n "$SMB_PASSWORD" ]; then
    if ! pdbedit -L | grep -q "^$USER_NAME:"; then
        (echo "$SMB_PASSWORD"; echo "$SMB_PASSWORD") | smbpasswd -a -s "$USER_NAME"
    else
        (echo "$SMB_PASSWORD"; echo "$SMB_PASSWORD") | smbpasswd -s "$USER_NAME"
    fi
    smbpasswd -e "$USER_NAME"
fi


if command -v avahi-daemon >/dev/null 2>&1; then
    mkdir -p /var/run/dbus /var/run/avahi-daemon /etc/avahi/services
    
    rm -f /var/run/dbus/pid
    dbus-daemon --system --fork 2>/dev/null || true
    sleep 1
    
    cat > /etc/avahi/avahi-daemon.conf <<EOF
[server]
host-name=timemachine
domain-name=local
use-ipv4=yes
use-ipv6=no
deny-interfaces=docker0,lo
allow-point-to-point=yes

[publish]
publish-addresses=yes
publish-workstation=yes

[reflector]
enable-reflector=yes
reflect-ipv=yes
EOF

    cat > /etc/avahi/services/timemachine.service <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name>TimeMachine</name>
  <service>
    <type>_smb._tcp</type>
    <port>445</port>
  </service>
  <service>
    <type>_adisk._tcp</type>
    <port>9</port>
    <txt-record>dk0=adVN=TimeMachine,adVF=0x82</txt-record>
    <txt-record>sys=waMA=0,adVF=0x100</txt-record>
  </service>
</service-group>
EOF

    if avahi-daemon --daemonize --no-chroot 2>/dev/null; then
        sleep 1
        pgrep -x avahi-daemon >/dev/null && echo "✓ Avahi iniciado" || echo "⚠ Avahi falló"
    fi
fi

exec "$@"