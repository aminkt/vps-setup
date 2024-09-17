#! /bin/bash

if [ -z "$1" ]
then
      "Domain is empty."
      exit
fi

DOMAIN_NAME=$1
CERT_DIRECTORY=/etc/nginx/letsencrypt/live/$DOMAIN_NAME
NGINX_CONFIG_FILE=/etc/nginx/letsencrypt/ssl.$DOMAIN_NAME.conf
ACME_COMMAND=/root/.acme.sh/acme.sh


echo "DOMAIN_NAME (Not subdomain): $DOMAIN_NAME"
echo "CERT_DIRECTORY: $CERT_DIRECTORY"
echo "NGINX_CONFIG_FILE: $NGINX_CONFIG_FILE"

if [ ! -f $ACME_COMMAND ]
then
    echo "GOING to setup acme.sh"
    read -p 'ACME script email: ' acme_email
    if [ -z "$acme_email" ]
    then
        "ACME email is rquired."
        exit
    fi
    curl https://get.acme.sh | sh -s email=$acme_email
    rm -rf master.tar.gz acme.sh-master
    # exit
fi

if [ ! -f .ssl_acme.env ]
then
read -p 'Cloadflare email: ' cloadflare_email
read -p 'Cloadflare apiKey: ' cloadflare_key

cat << EOF > .ssl_acme.env
CLOAD_FLARE_KEY=$cloadflare_key
CLOAD_FLARE_EMAIL=$cloadflare_email
EOF
fi

source .ssl_acme.env

export CF_Token=${CLOAD_FLARE_KEY}
export CF_Email=${CLOAD_FLARE_EMAIL}

curl -X GET "https://api.cloudflare.com/client/v4/zones"  -H "Authorization: Bearer $CF_Token" | jq

echo "Cloadflare mail IS $CF_EMail"
echo "Cloadflare api key IS $CF_Token"

$ACME_COMMAND --set-default-ca --server letsencrypt
echo "ACME is configured!"

$ACME_COMMAND --issue -d $DOMAIN_NAME -d *.$DOMAIN_NAME  --dns dns_cf --debug 2 --force

mkdir -p $CERT_DIRECTORY

$ACME_COMMAND --install-cert -d $DOMAIN_NAME \
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
