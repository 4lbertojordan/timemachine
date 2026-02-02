#!/bin/bash
set -e

# Set timezone if provided
if [ -n "$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

# Get user and group configuration from environment
USER_NAME=${SMB_USER:-jordancodes}
USER_UID=${SMB_UID:-1000}
GROUP_NAME=${SMB_GROUP:-home}
GROUP_GID=${SMB_GID:-1000}

# Create group if it doesn't exist
if ! getent group "$GROUP_NAME" >/dev/null; then
    echo "Creating group: $GROUP_NAME ($GROUP_GID)"
    groupadd -g "$GROUP_GID" "$GROUP_NAME"
fi

# Create system user if it doesn't exist
if ! id -u "$USER_NAME" >/dev/null 2>&1; then
    echo "Creating system user: $USER_NAME ($USER_UID)"
    useradd -u "$USER_UID" -g "$GROUP_GID" -M -s /sbin/nologin "$USER_NAME"
fi

# Verify Samba directory structure
echo "Verifying Samba directory structure..."
mkdir -p /var/lib/samba/private
mkdir -p /var/log/samba
mkdir -p /var/run/samba

# Set proper permissions for private directory
chmod 700 /var/lib/samba/private

# Configure Samba user password if provided
if [ -n "$SMB_PASSWORD" ]; then
    # Check if user database exists
    if ! pdbedit -L >/dev/null 2>&1; then
        echo "New or corrupted user database. Initializing..."
    fi

    # Create or update user
    if ! pdbedit -L | grep -q "^$USER_NAME:"; then
        echo "Initializing Samba user: $USER_NAME"
        (echo "$SMB_PASSWORD"; echo "$SMB_PASSWORD") | smbpasswd -a -s "$USER_NAME"
    else
        echo "Updating password for: $USER_NAME"
        (echo "$SMB_PASSWORD"; echo "$SMB_PASSWORD") | smbpasswd -s "$USER_NAME"
    fi
    
    # Enable the user account
    smbpasswd -e "$USER_NAME"
fi

# Start Samba
echo "Starting Samba..."
exec "$@"