#!/bin/bash
  
# Faz com que as mensagens comumns e de erro deste script apareçam tanto no
# terminal como em um arquivo de log
exec > >(tee -a "/tmp/update.sh.log") 2>&1

# Pretty Print
pprint() {
    printf "\n===============================\n$1\n===============================\n"
}

pull_rmod_container() {

    pprint "Obtendo versão mais atualizada do container LeggoR"
    sudo docker-compose pull
}

update_rmod_container() {

    pprint "Atualizando código LeggoR"
    git pull

    pprint "Atualizando imagem docker"
    sudo docker-compose build

}

fetch_leggo_data() {

pprint "Baixando e exportando novos dados"
sudo docker-compose run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p data/tabela_geral_ids_casa.csv \
       -e exported \
       -f 1

}

fetch_leggo_props() {

pprint "Baixando e exportando novos dados de proposições"
sudo docker-compose run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p data/tabela_geral_ids_casa.csv \
       -e exported \
       -f 2
}

fetch_leggo_emendas() {

pprint "Baixando e exportando novos dados de emendas"
sudo docker-compose run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p data/tabela_geral_ids_casa.csv \
       -e exported \
       -f 3
}

fetch_leggo_comissoes() {

pprint "Baixando e exportando novos dados de comissões"
sudo docker-compose run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p data/tabela_geral_ids_casa.csv \
       -e exported \
       -f 4
}

update_leggo_data() {

pprint "Atualizando dados do Leggo - Câmara"
sudo docker-compose run --rm rmod \
       Rscript scripts/update_leggo_data.R \
       data/tabela_geral_ids_casa.csv \
       exported camara

pprint "Atualizando dados do Leggo - Senado"
sudo docker-compose run --rm rmod \
       Rscript scripts/update_leggo_data.R \
       data/tabela_geral_ids_casa.csv \
       exported senado

}

process_leggo_data() {

pprint "Processando dados do Leggo"
sudo docker-compose run --rm rmod \
       Rscript scripts/process_leggo_data.R \
       exported \
       exported

}

update_distancias_emendas() {

pprint "Atualizando as emendas com as distâncias disponíveis"
sudo docker-compose run --rm rmod \
        Rscript scripts/update_emendas_dist.R \
        exported/emendas_with_distances \
        data/distancias \
        exported/emendas_raw.csv \
        exported/emendas.csv

}

update_pautas() {

pprint "Atualizando as pautas"
today=$(date +%Y-%m-%d)
lastweek=$(date -d '2 weeks ago' +%Y-%m-%d)
sudo docker-compose run --rm rmod \
        Rscript scripts/fetch_agenda.R \
        data/tabela_geral_ids_casa.csv \
        $lastweek $today \
        exported \
        exported/pautas.csv

}

update_db() {

pprint "Inserindo no BD"
# O id do container e nome pode mudar, mas parece sempre manter o "back_api" no começo
api_container_id=$(sudo docker ps | grep back_api | cut -f 1 -d ' ')
sudo docker exec $api_container_id \
     sh -c './manage.py flush --no-input; ./manage.py import_data'

}


cd /home/ubuntu/leggoR

# Prints script usage
print_usage() {
    printf "Uso Correto: ./update.sh <OPERATION_LABEL>\n"
    printf "Operation Labels:\n"
    printf "			-help: Imprime ajuda/uso correto do script\n"
    printf "			-build: Atualiza e faz build do container leggoR\n"
    printf "			-pull-docker: Atualiza container leggoR\n"
    printf "			-update-pautas: Baixa dados atualizados de pautas\n"
    printf "			-update-data: Baixa dados atualizados para o leggoR (versão nova)\n"
    printf "			-process-data: Process dados do leggoR\n"
    printf "			-fetch-data: Baixa dados para o leggoR (versão antiga)\n"
    printf "			-fetch-props: Baixa dados de proposições\n"
    printf "			-fetch-emendas: Baixa dados de emendas\n"
    printf "			-fetch-comissoes: Baixa dados de comissões\n"
    printf "			-update-emendas: Atualiza dados de emendas com distâncias atualizadas\n"
    printf "			-update-db: Importa dados atualizados para o Banco de Dados\n"

}

if [ "$#" -lt 1 ]; then
  echo "Número errado de parâmetros!"
  print_usage
  exit 1
fi

if [[ $@ == *'-help'* ]]; then print_usage; exit 0
fi

pprint "Iniciando atualização"
# Registra a data de início
date

if [[ $@ == *'-build'* ]]; then update_rmod_container
fi

if [[ $@ == *'-pull-docker'* ]]; then pull_rmod_container
fi

if [[ $@ == *'-update-pautas'* ]]; then update_pautas
fi

if [[ $@ == *'update-data'* ]]; then update_leggo_data
fi

if [[ $@ == *'process-data'* ]]; then process_leggo_data
fi

if [[ $@ == *'-fetch-data'* ]]; then fetch_leggo_data
fi

if [[ $@ == *'-fetch-props'* ]]; then fetch_leggo_props
fi

if [[ $@ == *'-fetch-emendas'* ]]; then fetch_leggo_emendas
fi

if [[ $@ == *'-fetch-comissoes'* ]]; then fetch_leggo_comissoes
fi

if [[ $@ == *'-update-emendas'* ]]; then update_distancias_emendas
fi

if [[ $@ == *'-update-db'* ]]; then update_db
fi

# Registra a data final
date
pprint "Feito!"

