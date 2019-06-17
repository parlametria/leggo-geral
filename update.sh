#!/bin/bash

# Faz com que as mensagens comumns e de erro deste script apareçam tanto no
# terminal como em um arquivo de log
exec > >(tee -a "/tmp/update.sh.log") 2>&1

# Finaliza script se algum comando der erro, mesmo em pipe
set -e
set -o pipefail

# Pretty Print
pprint() {
    printf "\n===============================\n$1\n===============================\n"
}

cd /home/ubuntu/agora-digital

pprint "Iniciando atualização"
# Registra a data de início
date

pprint "Atualizando código LeggoR"
git pull

pprint "Atualizando imagem docker"
# Não usa a cache de build para usar sempre a última versão do Rcongresso
sudo docker-compose build

#pprint "Removendo CSVs anteriores"
# Remove os CSVs antigos para evitar ficar em um estado inconsistente, com parte
# dos dados atualizados e outros não
#rm -f exported/*.csv

pprint "Baixando e exportando novos dados"
sudo docker-compose run --rm rmod \
        Rscript scripts/fetch_updated_bills_data.R \
        data/tabela_geral_ids_casa.csv \
        exported

pprint "Atualizando as emendas com as distâncias disponíveis"
sudo docker-compose run --rm rmod \
        Rscript scripts/update_emendas_dist.R \
        exported/emendas_with_distances \
        data/distancias \
        exported/emendas_raw.csv \
        exported/emendas.csv

pprint "    pautas"
today=$(date +%Y-%m-%d)
sudo docker-compose run --rm rmod \
     Rscript scripts/fetch_agenda.R \
     data/tabela_geral_ids_casa.csv \
     2019-01-01 $today \
     exported

pprint "Inserindo no BD"
# O id do container e nome pode mudar, mas parece sempre manter o "back_api" no começo
api_container_id=$(sudo docker ps | grep back_api | cut -f 1 -d ' ')
sudo docker exec $api_container_id \
     sh -c './manage.py flush --no-input; ./manage.py import_data'

# Registra a data final
date
pprint "Feito!"
