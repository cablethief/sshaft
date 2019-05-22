FROM        alpine:3.9

LABEL       maintainer="CableThief"
LABEL       repository="https://github.com/Cablethief/sshaft"
            
COPY        entrypoint.sh /
RUN         apk add --no-cache openssh \
            && chmod +x /entrypoint.sh \
            && rm -rf /var/cache/apk/* 

EXPOSE      22
ENTRYPOINT  ["/entrypoint.sh"]
