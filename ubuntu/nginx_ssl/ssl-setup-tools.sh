#! /bin/bash

if [ -z "$1" ]
then
      "Domain is empty."
      exit
fi

DOMAIN_NAME=$1
CERT_DIRECTORY=/etc/nginx/letsencrypt/live/$DOMAIN_NAME
NGINX_CONFIG_FILE=/etc/nginx/conf.d/ssl.conf
ACME_COMMAND=/root/.acme.sh/acme.sh


echo "DOMAIN_NAME (Not subdomain): $DOMAIN_NAME"
echo "CERT_DIRECTORY: $CERT_DIRECTORY"
echo "NGINX_CONFIG_FILE: $NGINX_CONFIG_FILE"

if [ ! -f $ACME_COMMAND ]
then
    echo "GOING to setup acme.sh"
    # curl https://get.acme.sh | sh
    rm -rf master.tar.gz acme.sh-master
    exit
fi

if [ ! -f .ssl_acme.env ]
then
read -p 'Cloadflare emil key: ' cloadflare_email
read -sp 'Cloadflare api key: ' cloadflare_key

echo "Saving api key data for $cloadflare_email"
export CF_Key=${cloadflare_key}
export CF_Email=${cloadflare_email}

cat << EOF > .ssl_acme.env
CF_Key=$CF_Key
CF_Email=$CF_Email
EOF
fi

source .ssl_acme.env

echo "Cloadflare api key IS $CF_Key"

echo "ACME is configured!"

$ACME_COMMAND --issue -d $DOMAIN_NAME -d *.$DOMAIN_NAME  --dns dns_cf -k ec-384 

mkdir -p $CERT_DIRECTORY

$ACME_COMMAND --install-cert -d $DOMAIN_NAME --ecc \
--cert-file $CERT_DIRECTORY/cert.pem \
--key-file $CERT_DIRECTORY/key.pem \
--fullchain-file $CERT_DIRECTORY/fullchain.pem \
--ca-file $CERT_DIRECTORY/ca.pem \
--reloadcmd "systemctl restart nginx.service"

cat <<EOF >$NGINX_CONFIG_FILE
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate $CERT_DIRECTORY/fullchain.pem;
    ssl_certificate_key     $CERT_DIRECTORY/key.pem;
    ssl_trusted_certificate $CERT_DIRECTORY/ca.pem;
EOF

echo "SSL is configured"
crontab -l
