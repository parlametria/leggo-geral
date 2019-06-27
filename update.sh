#!/bin/bash
  
# Faz com que as mensagens comumns e de erro deste script apareçam tanto no
# terminal como em um arquivo de log
exec > >(tee -a "/tmp/update.sh.log") 2>&1

# Pretty Print
pprint() {
    printf "\n===============================\n$1\n===============================\n"
}

update_rmod_container() {

    pprint "Atualizando código LeggoR"
#    git pull

    pprint "Atualizando imagem docker"
#    sudo docker-compose build

}

fetch_leggo_data() {

pprint "Baixando e exportando novos dados"
#sudo docker-compose run --rm rmod \
#       Rscript scripts/fetch_updated_bills_data.R \
#       data/tabela_geral_ids_casa.csv \
#       exported

}

update_distancias_emendas() {

pprint "Atualizando as emendas com as distâncias disponíveis"
#sudo docker-compose run --rm rmod \
#        Rscript scripts/update_emendas_dist.R \
#        exported/emendas_with_distances \
#        data/distancias \
#        exported/emendas_raw.csv \
#        exported/emendas.csv

}

update_pautas() {

pprint "Atualizando as pautas"
#today=$(date +%Y-%m-%d)
#lastweek=$(date -d '2 weeks ago' +%Y-%m-%d)
#sudo docker-compose run --rm rmod \
#        Rscript scripts/fetch_agenda.R \
#        data/tabela_geral_ids_casa.csv \
#        $lastweek $today \
#        exported \
#        exported/pautas.csv

}

update_db() {

pprint "Inserindo no BD"
## O id do container e nome pode mudar, mas parece sempre manter o "back_api" no começo
#api_container_id=$(sudo docker ps | grep back_api | cut -f 1 -d ' ')
#sudo docker exec $api_container_id \
#     sh -c './manage.py flush --no-input; ./manage.py import_data'

}


#cd /home/ubuntu/leggoR

pprint "Iniciando atualização"
# Registra a data de início
date

if [[ $@ == *'-build'* ]]; then update_rmod_container
fi

if [[ $@ == *'-fetch-pautas'* ]]; then update_pautas
fi

if [[ $@ == *'-fetch-data'* ]]; then fetch_leggo_data
fi

if [[ $@ == *'-update-emendas'* ]]; then update_distancias_emendas
fi

if [[ $@ == *'-update-db'* ]]; then update_db
fi


# Registra a data final
date
pprint "Feito!"

