FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# instalando os servicos da maquina
RUN apt-get update && apt-get install -y \
    apache2 \
    openssh-server \
    vsftpd \
    supervisor \
    libapache2-mod-php \
    net-tools\
    && rm -rf /var/lib/apt/lists/*

# criacao das pastas necessarias po SSH, FTP e Supervisor
RUN mkdir -p /var/run/sshd /var/log/supervisor /var/run/vsftpd/empty

# Configuracao do FTP anônimo apontando para a raiz padrao do vsftpd no Ubuntu
COPY vsftpd.conf /etc/vsftpd.conf

RUN sed -i 's/anonymous_enable=NO/anonymous_enable=YES/' /etc/vsftpd.conf && \
    mkdir -p /var/ftp/pub && \
    chown root:root /var/ftp && \
    chmod 755 /var/ftp && \
    chown -R ftp:ftp /var/ftp/pub && \
    echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf && \
    echo "anon_root=/var/ftp" >> /etc/vsftpd.conf

RUN echo "pasv_enable=YES" >> /etc/vsftpd.conf && \
    echo "pasv_min_port=40000" >> /etc/vsftpd.conf && \
    echo "pasv_max_port=40005" >> /etc/vsftpd.conf && \
    echo "pasv_address=127.0.0.1" >> /etc/vsftpd.conf

COPY hogwarts.txt /var/ftp/pub/hogwarts.txt
COPY Sala_Sonserina.txt /var/ftp/pub/Sala_Sonserina.txt

# criacao do usuario Sirius
RUN useradd -m -s /bin/bash Sirius && \
    echo "Sirius:O enigma do principe" | chpasswd

# Criacao do diretorio images
RUN mkdir -p /home/Sirius/images
RUN mkdir -p /home/Sirius/data

#SSh por autenticacao por senha 
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# copia das flags pros diretorios
COPY Sirius.jpeg /home/Sirius/images/Sirius.jpeg
COPY Marotos.jpeg /root/Marotos.jpeg

# colocando imagnes e textos
COPY Harry.jpeg /home/Sirius/images/Harry.jpeg
COPY Dobby.jpeg /home/Sirius/images/Dobby.jpeg

COPY caminho.txt /home/Sirius/data/caminho.txt
COPY dobby.txt /home/Sirius/data/dobby.txt

# ajustando as permissoes de imagem
RUN chown -R Sirius:Sirius /home/Sirius/images

# Aplicacao web: o vhost so responde a pedropettigrew.thm
# (o jogador precisa adicionar "IP pedropettigrew.thm" no /etc/hosts)
COPY web/ /var/www/html/
COPY ctf.conf /etc/apache2/sites-available/ctf.conf

# Apaga todo o conteudo padrao do Apache
RUN rm -rf /var/www/html/*

# Copia os arquivos da sua aplicacao
COPY web/ /var/www/html/
COPY ctf.conf /etc/apache2/sites-available/ctf.conf

RUN a2enmod php8.1 rewrite && a2dissite 000-default.conf && a2ensite ctf.conf

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Portas

EXPOSE 80 22 21

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
