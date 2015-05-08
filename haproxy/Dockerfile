FROM haproxy:1.5

RUN groupadd -r haproxy && useradd -r -g haproxy haproxy

RUN apt-get -y update && apt-get -y install \
  iptables \
  ca-certificates

COPY 50x-turbo.html /usr/local/etc/haproxy/errors/50x-turbo.html

COPY ssl-certs/*.pem /etc/ssl/private/
# RUN chmod 400 /etc/ssl/privat/*.pem

COPY route-backend.sh route-backend.sh
RUN chmod +x route-backend.sh

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
# RUN haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

EXPOSE 80 443
