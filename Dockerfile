# ==========================================
# 1. IMAGEM BASE E VARIÁVEIS DE AMBIENTE
# ==========================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ==========================================
# 2. INSTALAÇÃO DE SERVIÇOS E DEPENDÊNCIAS
# ==========================================
# instalando os servicos da maquina
RUN apt-get update && apt-get install -y \
    apache2 \
    openssh-server \
    vsftpd \
    supervisor \
    libapache2-mod-php \
    net-tools \
    sudo \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# criacao das pastas necessarias po SSH, FTP e Supervisor
RUN mkdir -p /var/run/sshd /var/log/supervisor /var/run/vsftpd/empty

# ==========================================
# 3. CONFIGURAÇÃO DO SERVIÇO VSFTPD (FTP)
# ==========================================
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

# ==========================================
# 4. CONFIGURAÇÃO DO USUÁRIO SIRIUS
# ==========================================
# criacao do usuario Sirius
RUN useradd -m -s /bin/bash Sirius && \
    echo "Sirius:O enigma do principe" | chpasswd

# Criacao do diretorio images
RUN mkdir -p /home/Sirius/images
RUN mkdir -p /home/Sirius/data

# Estrutura de pastas adicional para ambientacao do Sirius
RUN mkdir -p /home/Sirius/cartas_hogwarts \
             /home/Sirius/livros_proibidos \
             /home/Sirius/.secret_notes

RUN echo "Lembrete: O Mapa do Maroto requer a senha correta na aplicacao web." > /home/Sirius/cartas_hogwarts/bilhete.txt && \
    echo "Alquimia Avançada por Libatius Borage." > /home/Sirius/livros_proibidos/livro_pocos.txt && \
    echo "Juro solenemente não fazer nada de bom." > /home/Sirius/.secret_notes/juramento.txt

# SSh por autenticacao por senha 
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# copia das flags pros diretorios
COPY Sirius.jpeg /home/Sirius/images/Sirius.jpeg

# colocando imagnes e textos
COPY Harry.jpeg /home/Sirius/images/Harry.jpeg
COPY Dobby.jpeg /home/Sirius/images/Dobby.jpeg

COPY caminho.txt /home/Sirius/data/caminho.txt
COPY dobby.txt /home/Sirius/data/dobby.txt

# ajustando as permissoes de imagem
RUN chown -R Sirius:Sirius /home/Sirius

# ==========================================
# 5. CONFIGURAÇÃO DA APLICAÇÃO WEB (APACHE)
# ==========================================
# Aplicacao web: o vhost so responde a mapa_maroto.thm
# (o jogador precisa adicionar "IP mapa_maroto.thm" no /etc/hosts)

# Apaga todo o conteudo padrao do Apache
RUN rm -rf /var/www/html/*

# Copia os arquivos da sua aplicacao
COPY web/ /var/www/html/
COPY ctf.conf /etc/apache2/sites-available/ctf.conf

RUN a2enmod php8.1 rewrite && a2dissite 000-default.conf && a2ensite ctf.conf

# ==========================================
# 6. CONFIGURAÇÕES DO ROOT E VETOR DE PRIVESC
# ==========================================
# 2. Criar a pasta do desafio e diretório root interno
RUN mkdir -p /opt/profeta /root/root /root/registro_ordem /root/confidencial

# 3. Copiar os arquivos da aplicacao e flag de root na pasta /root/root/
COPY profeta_diario.py /opt/profeta/profeta_diario.py
COPY manchete.py /opt/profeta/manchete.py
COPY Marotos.jpeg /root/root/Marotos.jpeg

# Arquivos de ambientação na pasta do root
RUN echo "Membros ativos: Sirius Black, Remus Lupin, James Potter, Peter Pettigrew. E agora Você, Parabéns!" > /root/registro_ordem/membros.txt && \
    echo "Profecia referente ao Garoto Que Sobreviveu." > /root/confidencial/profecia.txt

# 4. Ajustar donos e permissoes dos arquivos
# profeta_diario.py: dono root, leitura/execucao para todos (755)
# manchete.py: gravavel por todos (666)
RUN chown -R root:root /opt/profeta /root && \
    chmod 700 /root && \
    chmod 755 /opt/profeta/profeta_diario.py && \
    chmod 666 /opt/profeta/manchete.py

# 5. Configurar a permissao do sudoers para o usuurio Sirius
RUN echo "Sirius ALL=(root) NOPASSWD: /usr/bin/python3 /opt/profeta/profeta_diario.py" > /etc/sudoers.d/profeta && \
    chmod 0440 /etc/sudoers.d/profeta

# ==========================================
# 7. SUPERVISOR E INICIALIZAÇÃO
# ==========================================
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Portas
EXPOSE 80 22 21

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]