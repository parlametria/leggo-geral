#!/bin/bash
  
# Faz com que as mensagens comumns e de erro deste script apareçam tanto no
# terminal como em um arquivo de log
exec > >(tee -a "/tmp/update.sh.log") 2>&1

# Pretty Print
pprint() {
    printf "\n===============================\n$1\n===============================\n"
}

# Function. 
# Param 1 is the return code
# Param 2 is text to display on failure.
check_errs() {
  if [ "${1}" -ne "0" ]; then
    echo "ERROR # ${1} : ${2}"
    # as a bonus, make our script exit with the right error code.
    exit ${1}
  else
    echo "Script ran successfully"
  fi
}

pull_rmod_container() {

    pprint "Obtendo versão mais atualizada do container LeggoR"
    docker-compose pull
}

build_leggor() {

    pprint "Atualizando código LeggoR"
    git pull

    pprint "Atualizando imagem docker"
    docker-compose build

}

fetch_leggo_data() {

pprint "Baixando e exportando novos dados"
docker-compose run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 1

}

fetch_leggo_props() {

pprint "Baixando e exportando novos dados de proposições"
docker-compose run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 2
}

fetch_leggo_emendas() {

pprint "Baixando e exportando novos dados de emendas"
docker-compose run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 3
}

fetch_leggo_comissoes() {

pprint "Baixando e exportando novos dados de comissões"
docker-compose run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 4
check_errs $? "Não foi possível baixar dados de comissões."
}

update_leggo_data() {

pprint "Atualizando dados do Leggo - Câmara"
docker-compose run --rm rmod \
       Rscript scripts/update_leggo_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH -c camara

pprint "Atualizando dados do Leggo - Senado"
docker-compose run --rm rmod \
       Rscript scripts/update_leggo_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH -c senado

}

process_leggo_data() {

pprint "Processando dados do Leggo"
docker-compose run --rm rmod \
       Rscript scripts/process_leggo_data.R \
       -f 1 \
       -d "2019-01-31" \
       -p 0.1 \
       -i $EXPORT_FOLDERPATH \
       -o $EXPORT_FOLDERPATH

}

update_distancias_emendas() {

pprint "Atualizando as emendas com as distâncias disponíveis"
docker-compose run --rm rmod \
        Rscript scripts/update_emendas_dist.R \
        $EXPORT_FOLDERPATH/emendas_with_distances \
        data/distancias \
        $EXPORT_FOLDERPATH/emendas_raw.csv \
        $EXPORT_FOLDERPATH/emendas.csv

}

update_pautas() {

pprint "Atualizando as pautas"
today=$(date +%Y-%m-%d)
lastweek=$(date -d '2 weeks ago' +%Y-%m-%d)
docker-compose run --rm rmod \
        Rscript scripts/fetch_agenda.R \
        $PLS_FILEPATH \
        $lastweek $today \
        $EXPORT_FOLDERPATH \
        $EXPORT_FOLDERPATH/pautas.csv

}

build_leggo_trends() {

pprint "Atualizando código Leggo Trends"
git pull

pprint "Atualizando imagem docker do Leggo Trends"
docker-compose -f $LEGGOTRENDS_COMPOSE_FILEPATH build

}

fetch_leggo_trends() {

pprint "Atualizando Pressão"
docker-compose -f $LEGGOTRENDS_COMPOSE_FILEPATH run --rm leggo-trends 
}

update_db() {

	pipeline=$1

	if [[ $pipeline == *'dev'* ]]; 
	then 

		pprint "Atualizando dados no BD do Backend Development"
		/snap/bin/heroku run python manage.py update_db_remotely -a leggo-backend-development 2>&1 | tee /tmp/heroku-dev-update-log.txt

	elif [[ $@ == *'prod'* ]];
	then

		pprint "Atualizando dados no BD do Backend Production"
		/snap/bin/heroku run python manage.py update_db_remotely -a leggo-backend-production 2>&1 | tee /tmp/heroku-prod-update-log.txt

	fi
}

run_pipeline() {
	#Build container with current codebase
	build_leggor
       build_leggo_trends

	#Fetch and Process Prop metadata and tramitação
	fetch_leggo_props

	#Fetch Prop emendas
	fetch_leggo_emendas

	#Compute Pressão
       fetch_leggo_trends

	#Fetch related documents
	update_leggo_data

	#Process related documents
	process_leggo_data
}

source .env

cd $LEGGOR_FOLDERPATH

# Prints script usage
print_usage() {
    printf "Uso Correto: ./update.sh <OPERATION_LABEL>\n"
    printf "Operation Labels:\n"
    printf "			-help: Imprime ajuda/uso correto do script\n"
    printf "			-build-leggor: Atualiza e faz build do container leggoR\n"
    printf "			-pull-docker: Atualiza container leggoR\n"
    printf "			-update-pautas: Baixa dados atualizados de pautas\n"
    printf "			-update-data: Baixa dados atualizados para o leggoR (versão nova)\n"
    printf "			-process-data: Process dados do leggoR\n"
    printf "			-fetch-data: Baixa dados para o leggoR (versão antiga)\n"
    printf "			-fetch-props: Baixa dados de proposições\n"
    printf "			-fetch-emendas: Baixa dados de emendas\n"
    printf "			-fetch-comissoes: Baixa dados de comissões\n"
    printf "			-update-emendas: Atualiza dados de emendas com distâncias atualizadas\n"
    printf "			-update-db-dev: Importa dados atualizados para o Banco de Dados do Backend Dev\n"
    printf "			-update-db-prod: Importa dados atualizados para o Banco de Dados do Backend Prod\n"
    printf "                -run-pipeline: Roda pipeline completo de atualização de dados do Leggo\n"
    printf "                -leggo-trends: Atualiza e faz o build do Container Leggo Trends\n"
    printf "                -fetch-leggo-trends: Computa dados para a Pressão usando o Leggo Trends\n"
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

if [[ $@ == *'-build-leggor'* ]]; then build_leggor
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

if [[ $@ == *'-update-db-dev'* ]]; then update_db dev
fi

if [[ $@ == *'-update-db-prod'* ]]; then update_db prod
fi

if [[ $@ == *'-run-pipeline'* ]]; then run_pipeline
fi

if [[ $@ == *'-build-leggo-trends'* ]]; then build_leggo_trends
fi

if [[ $@ == *'-fetch-leggo-trends'* ]]; then fetch_leggo_trends
fi


# Registra a data final
date
pprint "Feito!"

