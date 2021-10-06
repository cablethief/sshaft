#!/bin/sh

# generate host keys if not present
ssh-keygen -A

# Supported Enviroment Variables.
# USERNAME=testing
# PASSWORD=testing
# ROOT_PASSWORD=Testing
# ROOT_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVjqZUJsFB3+97PGoyuDreXu6o9YBUXkFcr8Sl6FQ5w system"
# SSH_PORT=22
# ENABLE_SHELL=true
# ENABLE_IPV6=true
# PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVjqZUJsFB3+97PGoyuDreXu6o9YBUXkFcr8Sl6FQ5w system"

# Allow users to bind to all the dockers interfaces.
sed -i "s/GatewayPorts no/GatewayPorts yes/" /etc/ssh/sshd_config
sed -i "s/AllowTcpForwarding no/AllowTcpForwarding yes/" /etc/ssh/sshd_config
#GatewayPorts no

# Make sure we only listen on ipv6 else port forwards in docker get a bit wonkey
# Docker disables ipv6 by default and this makes sshd upset https://docs.docker.com/v17.09/engine/userguide/networking/default_network/ipv6/
if [[ ! "${ENABLE_IPV6}" = "true" ]] ; then
    sed -i "s/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/" /etc/ssh/sshd_config
fi

if [[ ! "${ENABLE_SHELL}" = "true" ]] ; then
    echo "Trying to make sure only port forwarding is allowed, use plink/ssh -N flag"
    echo 'echo "ForceCommand /bin/true" >> /etc/ssh/sshd_config'
    echo "ForceCommand /bin/true" >> /etc/ssh/sshd_config
    echo "If you want a shell use the enviromental variable 'ENABLE_SHELL=true'"
fi

if [[ -n "${ROOT_PASSWORD}" ]] ; then
    echo "Root user enabled, using the password: ${ROOT_PASSWORD}."
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
    echo "root:${ROOT_PASSWORD}" | chpasswd
fi

if [[ -n "${ROOT_PUBKEY}" ]]; then
    echo "Adding public key to root user: ${ROOT_PUBKEY}"
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
    mkdir -p /root/.ssh
    echo "${ROOT_PUBKEY}" >> /root/.ssh/authorized_keys

    if [[ -z "${ROOT_PASSWORD}" ]]; then
        ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
        echo "Setting a password to enable the root user so randomly generating one..."
        echo "Root user enabled, using the password: ${ROOT_PASSWORD}"
        echo "root:${ROOT_PASSWORD}" | chpasswd
    fi
fi

if [[ -n "${SSH_PORT}" ]] ; then
    echo "Setting SSH port to ${SSH_PORT}."
    sed -i "s/#Port.*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
fi

if [[ -n "${USERNAME}" ]]; then
    echo "Creating user: ${USERNAME}"
    echo "Please keep in mind normal users cannot bind to ports lower than 1024"
    echo "If your kernel is recent enough you may try '--sysctl net.ipv4.ip_unprivileged_port_start=0' with docker to allow it"
    if [[ ! "${ENABLE_SHELL}" = "true" ]] ; then
        adduser -S "${USERNAME}"
    else
        adduser -s "/bin/sh" -S "${USERNAME}"
    fi
    if [[ -n "${PUBKEY}" ]]; then
        echo "Adding public key: ${PUBKEY}"
        mkdir -p /home/${USERNAME}/.ssh
        echo ${PUBKEY} >> /home/${USERNAME}/.ssh/authorized_keys
    fi
    if [[ -n "${PASSWORD}" ]]; then
        echo "Using password: ${PASSWORD}"
        echo "${USERNAME}:${PASSWORD}" | chpasswd
    fi
fi

# do not detach (-D), log to stderr (-e), passthrough other arguments
/usr/sbin/sshd -D -e "$@"
