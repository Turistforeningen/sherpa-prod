FROM haproxy:1.5

EXPOSE 80 443

RUN apt-get -y update && \
    apt-get -y install iptables

COPY route-backend.sh route-backend.sh
RUN chmod +x route-backend.sh

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
