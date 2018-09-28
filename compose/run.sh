#! /usr/bin/env bash

source .env

read -d '' help << EOF
Roda comandos docker-compose usando as configurações de múltiplos repositórios.
O primeiro parâmetro deve ser 'dev' ou 'prod', os seguintes serão passados diretamente para o docker-compose.
Ex.:
./run.sh dev up
EOF

if [ $# -lt 1 ]; then
    echo $help
    exit
fi;

if [ $1 == 'dev' ]; then
    docker-compose -f docker-compose.yml -f ${FRONTEND_PATH}/docker-compose.yml -f ${BACKEND_PATH}/docker-compose.yml -f ${BACKEND_PATH}/docker-compose.override.yml ${@:2}
elif [ $1 == 'prod' ]; then
    docker-compose -f docker-compose.yml -f ${FRONTEND_PATH}/deploy/prod.yml -f ${BACKEND_PATH}/docker-compose.yml -f ${BACKEND_PATH}/deploy/prod.yml ${@:2}
else
    echo $help
fi;
