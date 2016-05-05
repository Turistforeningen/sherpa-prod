#!/usr/bin/env bash

DOMAIN=$1
WWW=$2

DOCKER_MACHINE_VERSION=`docker-machine --version`
LETSENCRYPT_MACHINE="letsencrypt.hw.dnt.no"
CERTS_DIR=`pwd`/ssl-certs
CERT_FILE=${CERTS_DIR}/${DOMAIN}.pem
USAGE="""Usage: $0 <domain name> [www]\n\nInclude the [www] argument to add www.<domain name> to the certificate"""

if [ -z "${DOMAIN}" ]; then
  echo -e ${USAGE}
  exit 1
fi

if [ -z "${WWW}" ]; then
  LETSENCRYPT_DOMAIN_ARGS="-d ${DOMAIN}"
elif [ "${WWW}" == "www" ]; then
  LETSENCRYPT_DOMAIN_ARGS="-d ${DOMAIN} -d www.${DOMAIN}"
else
  echo -e ${USAGE}
  exit 1
fi

if [[ ! "${DOCKER_MACHINE_VERSION}" =~ ^docker-machine\ version\ 0.6. ]]; then
  echo "Sorry, this script is compatible with docker-machine version 0.6; you're running: ${DOCKER_MACHINE_VERSION}"
  exit 1
fi

eval "$(docker-machine env ${LETSENCRYPT_MACHINE})"
ACTIVE_MACHINE=`docker-machine active`
if [ "${ACTIVE_MACHINE}" != "${LETSENCRYPT_MACHINE}" ]; then
  echo "Please add ${LETSENCRYPT_MACHINE} to your Docker machines."
  exit 1
fi

if [ ! -e $CERTS_DIR ]; then
  echo "Certificate directory ${CERTS_DIR} does not exist."
  exit 1
fi

if [ -e ${CERT_FILE} ]; then
  echo "Certificate ${CERT_FILE} already exists."
  exit 1
fi

echo "Domain name args for letsencrypt: ${LETSENCRYPT_DOMAIN_ARGS}"
read -p "Continue? [y/N] " yn
case $yn in
  [Yy]*) ;;
  *) exit 0;;
esac

echo "Requesting certificate with ${LETSENCRYPT_MACHINE}, please wait..."
docker run \
  -it \
  --rm \
  -v /certs:/etc/letsencrypt/archive \
  --name letsencrypt \
  -p 0.0.0.0:80:80 \
  quay.io/letsencrypt/letsencrypt \
    certonly \
    --standalone \
    --standalone-supported-challenges http-01 \
    --agree-tos \
    --register-unsafely-without-email \
    ${LETSENCRYPT_DOMAIN_ARGS}

DOCKER_RUN_STATUS=$?

if [ $DOCKER_RUN_STATUS -ne 0 ]; then
  echo "Certificate issuance exited with code ${DOCKER_RUN_STATUS}, aborting..."
  exit $DOCKER_RUN_STATUS
fi

echo "Done, moving certificate to your local machine..."
docker-machine scp ${LETSENCRYPT_MACHINE}:/certs/${DOMAIN}/privkey1.pem ${CERT_FILE}-key
docker-machine scp ${LETSENCRYPT_MACHINE}:/certs/${DOMAIN}/fullchain1.pem ${CERT_FILE}-chain
cat ${CERT_FILE}-key ${CERT_FILE}-chain > ${CERT_FILE}
rm ${CERT_FILE}-key ${CERT_FILE}-chain
docker-machine ssh ${LETSENCRYPT_MACHINE} "sudo rm -rf /certs/${DOMAIN}/"
echo "Ok, your certificate is stored in: ${CERT_FILE}"
