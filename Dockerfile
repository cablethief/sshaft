FROM        alpine:3

LABEL       maintainer="CableThief"
LABEL       repository="https://github.com/Cablethief/sshaft"
            
COPY        entrypoint.sh /
RUN         apk add --no-cache openssh \
            && chmod +x /entrypoint.sh \
            && rm -rf /var/cache/apk/* 
            # For when LinuxKit updates its kernel ):
            # && sysctl net.ipv4.ip_unprivileged_port_start=0

EXPOSE      22
ENTRYPOINT  ["/entrypoint.sh"]
