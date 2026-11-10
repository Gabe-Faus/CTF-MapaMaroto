[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:apache2]
command=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"
autorestart=true

[program:sshd]
command=/usr/sbin/sshd -D
autorestart=true

[program:vsftpd]
command=/usr/sbin/vsftpd /etc/vsftpd.conf
autorestart=true