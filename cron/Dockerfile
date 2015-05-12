FROM ubuntu:14.04

RUN apt-get -y update
RUN apt-get -y --no-install-recommends install cron

COPY crontab /crontab
RUN cat /crontab | crontab && rm /crontab
