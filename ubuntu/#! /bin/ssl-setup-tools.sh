#! /bin/bash

if ! command -v acme.sh &> /dev/null
then
    curl https://get.acme.sh | sh
    exit
fi

export CF_Key="sdfsdfsdfljlbjkljlkjsdfoiwje"
export CF_Email="hi@acme.sh"
