FROM ubuntu:14.04

RUN apt-get -y update
RUN apt-get -y --no-install-recommends install cron wget git
RUN wget --no-check-certificate -qO- https://get.docker.com/ | sh
RUN wget -qO- https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose
RUN mkdir /cron
RUN git clone https://github.com/Turistforeningen/sherpa-prod.git /cron/sherpa-prod

# Make the sherpa submodule read-only
RUN sed -i "s/git@github.com:Turistforeningen\/sherpa.git/https:\/\/github.com\/Turistforeningen\/sherpa.git/g" /cron/sherpa-prod/.gitmodules
RUN cd /cron/sherpa-prod && git submodule update --init sherpa

COPY pull.sh /cron/pull.sh
COPY sha.sh /cron/sha.sh
COPY run-sherpa.sh /cron/run-sherpa.sh
RUN chmod +x /cron/pull.sh /cron/sha.sh /cron/run-sherpa.sh

COPY crontab /cron/crontab
RUN cat /cron/crontab | crontab && rm /cron/crontab
