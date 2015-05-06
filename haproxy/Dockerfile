FROM haproxy:1.5

EXPOSE 80 443

RUN apt-get -y update && \
    apt-get -y install iptables

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
