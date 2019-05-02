#!/bin/bash

# Faz com que as mensagens comumns e de erro deste script apareçam tanto no
# terminal como em um arquivo de log
exec > >(tee -a "/tmp/update_emendas.sh.log") 2>&1

# Finaliza script se algum comando der erro, mesmo em pipe
set -e
set -o pipefail

# Pretty Print
pprint() {
    printf "\n===============================\n$1\n===============================\n"

}

if [ $# -ne 4 ]; then
  pprint "Wrong number of arguments!\nUsage: update_emendas.sh <leggoR_folderpath> <emendas_raw_filepath> <distances_folderpath> <emendas_dist_filepath>"
  exit 1
fi

leggo_folderpath=$1
emendas_raw_filepath=$2
distances_folderpath=$3
emendas_dist_filepath=$4

# Entra no diretório passado como argumento na chamada do script
cd $leggo_folderpath

pprint "Iniciando atualização"
# Registra a data de início
date

pprint "Baixando e exportando distâncias para novas emendas"
today=$(date +%Y-%m-%d)
Rscript scripts/update_emendas_dist.R \
     $emendas_raw_filepath \
     $distances_folderpath \
     $emendas_dist_filepath

pprint "Inserindo no BD"
# O id do container e nome pode mudar, mas parece sempre manter o "back_api" no começo
api_container_id=$(sudo docker ps | grep back_api | cut -f 1 -d ' ')
sudo docker exec $api_container_id \
     sh -c './manage.py flush --no-input; ./manage.py import_data'

# Registra a data final
date
pprint "Feito!"