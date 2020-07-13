#!/bin/bash

# Carrega variáveis de ambiente
source .env

# Adiciona possiveis caminhos de bibliotecas ao PATH
PATH=$PATH:/usr/local/bin

# Cria o diretório destino dos logs deste script
mkdir -p $LOG_FOLDERPATH

# Gera o nome do arquivo do log a partir do timestamp 
timestamp=$(date '+%d_%m_%Y_%H_%M_%S');
log_filepath="${LOG_FOLDERPATH}${timestamp}.txt"

# Faz com que as mensagens comumns e de erro deste script apareçam tanto no
# terminal como em um arquivo de log
exec > >(tee -a $log_filepath) 2>&1

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
  fi
}

build_leggor() {

pprint "Atualizando código do rcongresso"
curr_branch=`git -C $LEGGOR_FOLDERPATH/rcongresso rev-parse --abbrev-ref HEAD`
git -C $LEGGOR_FOLDERPATH/rcongresso pull origin $curr_branch

pprint "Atualizando código do LeggoR"
curr_branch=`git -C $LEGGOR_FOLDERPATH rev-parse --abbrev-ref HEAD`
git -C $LEGGOR_FOLDERPATH pull origin $curr_branch

pprint "Atualizando imagem docker"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml build --build-arg clone_rcongresso=false rmod
check_errs $? "Não foi possível fazer o build do leggoR."

}

fetch_leggo_data() {

pprint "Baixando e exportando novos dados"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 1
check_errs $? "Não foi possível baixar dados de proposições, emendas e comissões."

}

fetch_leggo_props() {

pprint "Baixando e exportando novos dados de proposições"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 2
check_errs $? "Não foi possível baixar dados de proposições."

}

fetch_leggo_emendas() {

pprint "Baixando e exportando novos dados de emendas"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 3
check_errs $? "Não foi possível baixar dados de emendas."

}

fetch_leggo_comissoes() {

pprint "Baixando e exportando novos dados de comissões"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 4
check_errs $? "Não foi possível baixar dados de comissões."

}

update_leggo_data() {

pprint "Atualizando dados do Leggo - Câmara"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/update_leggo_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH -c camara
check_errs $? "Não foi possível atualizar dados de documentos na Câmara."

pprint "Atualizando dados do Leggo - Senado"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/update_leggo_data.R \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH -c senado
check_errs $? "Não foi possível atualizar dados de documentos no Senado."

}

process_leggo_data() {

pprint "Processando dados do Leggo"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/process_leggo_data.R \
       -f 1 \
       -d "2019-01-31" \
       -p 0.1 \
       -i $EXPORT_FOLDERPATH \
       -o $EXPORT_FOLDERPATH
check_errs $? "Não foi possível processar dados dos documentos baixados."

}

update_distancias_emendas() {

pprint "Atualizando as emendas com as distâncias disponíveis"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
        Rscript scripts/update_emendas_dist.R \
        $EXPORT_FOLDERPATH/raw_emendas_distances \
        $EXPORT_FOLDERPATH/distancias \
        $EXPORT_FOLDERPATH/novas_emendas.csv \
        $EXPORT_FOLDERPATH/emendas.csv
check_errs $? "Não foi possível atualizar as distâncias advindas da análise de emendas."

}

update_pautas() {

pprint "Atualizando as pautas"
today=$(date +%Y-%m-%d)
lastweek=$(date -d '2 weeks ago' +%Y-%m-%d)
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
        Rscript scripts/fetch_agenda.R \
        $PLS_FILEPATH \
        $lastweek $today \
        $EXPORT_FOLDERPATH \
        $EXPORT_FOLDERPATH/pautas.csv
check_errs $? "Não foi possível atualizar as pautas."

}

build_leggo_trends() {

pprint "Atualizando código do LeggoTrends"
curr_branch=`git -C $LEGGOTRENDS_FOLDERPATH rev-parse --abbrev-ref HEAD`
git -C $LEGGOTRENDS_FOLDERPATH pull origin $curr_branch

pprint "Atualizando imagem docker"
docker-compose -f $LEGGOTRENDS_FOLDERPATH/docker-compose.yml build
check_errs $? "Não foi possível fazer o build do leggoTrends."

}

fetch_leggo_trends() {

pprint "Atualizando Pressão"

pprint "Gerando dataframe com os apelidos para busca no Twitter e Google Trends"
docker-compose -f $LEGGOTRENDS_FOLDERPATH/docker-compose.yml run --rm leggo-trends \
       Rscript gera_entrada_google_trends.R \
       -p leggo_data/proposicoes.csv \
       -i leggo_data/interesses.csv \
       -a leggo_data/apelidos.csv
check_errs $? "Não foi possível gerar os dados de apelidos das proposições."

pprint "Gerando dados de pressão do Google Trends"
docker-compose -f $LEGGOTRENDS_FOLDERPATH/docker-compose.yml run --rm leggo-trends \
       python3 fetch_google_trends.py \
       leggo_data/apelidos.csv \
       leggo_data/pops/
check_errs $? "Não foi possível baixar dados de pressão pelo Google Trends."

pprint "Gerando dados de popularidade do Twitter"
docker-compose -f $LEGGOTRENDS_FOLDERPATH/docker-compose.yml \
       run --rm leggo-trends \
       Rscript scripts/tweets_from_last_days/export_tweets_from_last_days.R \
       -a leggo_data/apelidos.csv \
       -o leggo_data/ 
check_errs $? "Não foi possível baixar dados de pressão pelo Twitter."

pprint "Gerando índice de popularidade combinando Twitter e Google Trends"
docker-compose -f $LEGGOTRENDS_FOLDERPATH/docker-compose.yml run --rm leggo-trends \
       Rscript scripts/popularity/export_popularity.R \
       -t leggo_data/trends.csv \
       -g leggo_data/pops/ \
       -o leggo_data/pressao.csv
check_errs $? "Não foi possível combinar os dados de pressão do Twitter e Google Trends."

}

build_versoes_props() {

pprint "Atualizando código do Versões Proposições"
curr_branch=`git -C $VERSOESPROPS_FOLDERPATH rev-parse --abbrev-ref HEAD`
git -C $VERSOESPROPS_FOLDERPATH pull origin $curr_branch

pprint "Atualizando imagem docker"
docker-compose -f $VERSOESPROPS_FOLDERPATH/docker-compose.yml build
check_errs $? "Não foi possível fazer o build do versoes-de-proposicoes."

}

fetch_versoes_props() {

docker-compose -f $VERSOESPROPS_FOLDERPATH/docker-compose.yml run --rm versoes_props \
       Rscript fetcher.R -o data/emendas_raw_old.csv \
       -e data/emendas_raw.csv \
       -n leggo_content_data/novas_emendas.csv \
       -a leggo_content_data/avulsos_iniciais.csv \
       -t leggo_content_data/textos.csv \
       -f 1 
check_errs $? "Não foi possível baixar dados de emendas e dos textos originais dos PLs."
}

build_leggo_content() {

pprint "Atualizando código do Leggo Content"
curr_branch=`git -C $LEGGOCONTENT_FOLDERPATH rev-parse --abbrev-ref HEAD`
git -C $LEGGOCONTENT_FOLDERPATH pull origin $curr_branch

pprint "Atualizando imagem docker"
docker-compose -f $LEGGOCONTENT_FOLDERPATH/docker-compose.yml build
check_errs $? "Não foi possível fazer o build do leggo-content."

}

process_leggo_content() {

docker-compose -f $LEGGOCONTENT_FOLDERPATH/docker-compose.yml run --rm leggo-content \
       ./run_emendas_analysis.sh ./leggo_content_data ./leggo_data
check_errs $? "Não foi possível analisar as emendas baixadas."

}

update_db() {

	pipeline=$1

	if [[ $pipeline == *'dev'* ]]; 
	then 

		pprint "Atualizando dados no BD do Backend Development"
		/snap/bin/heroku run python manage.py update_db_remotely -a $DEV_BACK_APP

	elif [[ $@ == *'prod'* ]];
	then

		pprint "Atualizando dados no BD do Backend Production"
		/snap/bin/heroku run python manage.py update_db_remotely -a $PROD_BACK_APP

	fi
       check_errs $? "Não foi possível atualizar os dados no BD do Heroku."
}

update_db_insights() {

	pipeline=$1

	if [[ $pipeline == *'dev'* ]]; 
	then 

		pprint "Atualizando dados de Insights no BD do Backend Development"
		/snap/bin/heroku run python manage.py update_insights_remotely -a $DEV_BACK_APP

	elif [[ $@ == *'prod'* ]];
	then

		pprint "Atualizando dados de Insights no BD do Backend Production"
		/snap/bin/heroku run python manage.py update_insights_remotely -a $PROD_BACK_APP

	fi
       check_errs $? "Não foi possível atualizar os dados de Insights no BD do Heroku."
}

setup_leggo_data_volume() {

       # Copy props tables to volume
       docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
        cp inst/extdata/tabela_geral_ids_casa.csv inst/extdata/tabela_geral_ids_casa_new.csv \
        $EXPORT_FOLDERPATH
       check_errs $? "Não foi possível copiar as tabelas de proposições para o volume leggo_data."

       # Create folders for docs data
       docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
        mkdir -p $EXPORT_FOLDERPATH/camara \
        $EXPORT_FOLDERPATH/senado
       check_errs $? "Não foi possível criar as pastas de documentos no volume leggo_data."

       # Copy deputados data to their respective folder
       docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
        cp inst/extdata/camara/parlamentares.csv \
        $EXPORT_FOLDERPATH/camara/parlamentares.csv
       check_errs $? "Não foi possível copiar os dados dos deputados para o volume leggo_data."
        
       # Copy senadores data to their respective folder
       docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
        cp inst/extdata/senado/parlamentares.csv \
        $EXPORT_FOLDERPATH/senado/parlamentares.csv
       check_errs $? "Não foi possível copiar os dados dos senadores para o volume leggo_data."
               
       # Copy parliamentarians data to their respective folder
       docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
        cp inst/extdata/parlamentares.csv \
        $EXPORT_FOLDERPATH/parlamentares.csv
       check_errs $? "Não foi possível copiar os dados dos parlamentares para o volume leggo_data."
       
}

processa_pls_interesse() {

pprint "Junta PL's de todos os interesses"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/interesses/export_pls_leggo.R \
       -u $URL_INTERESSES \
       -e $EXPORT_FOLDERPATH/pls_interesses.csv

}

processa_interesses() {

pprint "Processa o mapeamento de pls e interesses"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/interesses/export_mapeamento_interesses.R \
       -u $URL_INTERESSES \
       -p $EXPORT_FOLDERPATH/proposicoes.csv \
       -e $EXPORT_FOLDERPATH/interesses.csv

}

process_anotacoes() {
pprint "Processa os dados de anotações"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/anotacoes/export_anotacoes.R \
       -u $URL_LISTA_ANOTACOES \
       -i $EXPORT_FOLDERPATH/pls_interesses.csv \
       -p $EXPORT_FOLDERPATH/proposicoes.csv \
       -e $EXPORT_FOLDERPATH
}

atualiza_parlamentares() {
pprint "Atualiza dados dos parlamentares"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/parlamentares/update_parlamentares.R \
       -p $EXPORT_FOLDERPATH
}

run_pipeline_leggo_content() {
       #Build container with current codebase
       build_leggo_content

       # Analyze text
       process_leggo_content

       # Aggregate emendas distances
       update_distancias_emendas
}

run_pipeline() {
       run_analise_emendas=$1

	#Build container with current codebase
	build_leggor
       build_leggo_trends

       #Setup volume of leggo data
       setup_leggo_data_volume

       processa_pls_interesse

	#Fetch and Process Prop metadata and tramitação
       fetch_leggo_props

       processa_interesses

       # Fetch and Process anotações
       process_anotacoes

	#Compute Pressão
       fetch_leggo_trends

	#Fetch related documents
	update_leggo_data

	#Process related documents
	process_leggo_data

       #Fetch comissões
       fetch_leggo_comissoes

       #Update pautas
       update_pautas

       if [[ $run_analise_emendas == 1 ]]; 
	then 
              #Run emendas analysis
              run_pipeline_leggo_content
       fi
}


cd $WORKSPACE_FOLDERPATH

# Prints script usage
print_usage() {
    printf "Uso Correto: ./update.sh <OPERATION_LABEL>\n"
    printf "Operation Labels:\n"
    printf "\t-help: Imprime ajuda/uso correto do script\n"
    printf "\t-build-leggor: Atualiza e faz build do container leggoR\n"
    printf "\t-pull-docker: Atualiza container leggoR\n"
    printf "\t-update-pautas: Baixa dados atualizados de pautas\n"
    printf "\t-update-data: Baixa dados atualizados para o leggoR (versão nova)\n"
    printf "\t-process-data: Process dados do leggoR\n"
    printf "\t-fetch-data: Baixa dados para o leggoR (versão antiga)\n"
    printf "\t-fetch-props: Baixa dados de proposições\n"
    printf "\t-fetch-emendas: Baixa dados de emendas\n"
    printf "\t-fetch-comissoes: Baixa dados de comissões\n"
    printf "\t-update-emendas: Atualiza dados de emendas com distâncias atualizadas\n"
    printf "\t-update-db-dev: Importa dados atualizados para o Banco de Dados do Backend Dev\n"
    printf "\t-update-db-prod: Importa dados atualizados para o Banco de Dados do Backend Prod\n"
    printf "\t-run-basic-pipeline: Roda pipeline básico de atualização de dados do Leggo (sem análise de emendas)\n"
    printf "\t-run-full-pipeline: Roda pipeline completo de atualização de dados do Leggo\n"
    printf "\t-run-pipeline-leggo-content: Roda pipeline para análise das Emendas\n"
    printf "\t-build-leggo-trends: Atualiza e faz o build do Container Leggo Trends\n"
    printf "\t-fetch-leggo-trends: Computa dados para a Pressão usando o Leggo Trends\n"
    printf "\t-build-versoes-props: Atualiza e faz o build do Container Versões Props\n"
    printf "\t-fetch-versoes-props: Computa dados para a Pressão usando o Versões Props\n"
    printf "\t-build-leggo-content: Atualiza e faz o build do Container Leggo Content\n"
    printf "\t-process-leggo-content: Processa dados de textos/conteúdo usando o Leggo Content\n"
    printf "\t-process-anotacoes: Processa dados de anotações\n"
    printf "\t-update-db-insights-dev: Importa dados atualizados de Insights para o Banco de Dados do Backend Dev\n"
    printf "\t-update-db-insights-prod: Importa dados atualizados de Insights para o Banco de Dados do Backend Prod\n"
    printf "\t-atualiza-parlamentares: Atualiza os dados dos parlamentares\n"

    
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

if [[ $@ == *'-update-db-insights-dev'* ]]; then update_db_insights dev
fi

if [[ $@ == *'-update-db-insights-prod'* ]]; then update_db_insights prod
fi

if [[ $@ == *'-run-basic-pipeline'* ]]; then run_pipeline 0
fi

if [[ $@ == *'-run-full-pipeline'* ]]; then run_pipeline 1
fi

if [[ $@ == *'-run-pipeline-leggo-content'* ]]; then run_pipeline_leggo_content
fi

if [[ $@ == *'-build-leggo-trends'* ]]; then build_leggo_trends
fi

if [[ $@ == *'-fetch-leggo-trends'* ]]; then fetch_leggo_trends
fi

if [[ $@ == *'-build-versoes-props'* ]]; then build_versoes_props
fi

if [[ $@ == *'-fetch-versoes-props'* ]]; then fetch_versoes_props
fi

if [[ $@ == *'-build-leggo-content'* ]]; then build_leggo_content
fi

if [[ $@ == *'-process-leggo-content'* ]]; then process_leggo_content
fi

if [[ $@ == *'-process-anotacoes'* ]]; then process_anotacoes
fi

if [[ $@ == *'-atualiza-parlamentares'* ]]; then atualiza_parlamentares
fi

# Registra a data final
date
pprint "Feito!"

