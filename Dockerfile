FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apache2 \
    openssh-server \
    vsftpd \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY web/ /var/www/html/

EXPOSE 80 22 21

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
