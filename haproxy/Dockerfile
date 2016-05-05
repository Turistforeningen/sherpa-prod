FROM haproxy:1.6

RUN groupadd -r haproxy && useradd -r -g haproxy haproxy

RUN apt-get -y update && apt-get -y install \
  iptables \
  ca-certificates

COPY errorfiles/500.html /usr/local/etc/haproxy/errors/500.html
COPY errorfiles/502.html /usr/local/etc/haproxy/errors/502.html
COPY errorfiles/503.html /usr/local/etc/haproxy/errors/503.html
COPY errorfiles/504.html /usr/local/etc/haproxy/errors/504.html

COPY ssl-certs/*.pem /etc/ssl/private/

COPY route-backend.sh route-backend.sh
RUN chmod +x route-backend.sh

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

EXPOSE 80 443
