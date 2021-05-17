#!/bin/bash

# Carrega variáveis de ambiente
source .env

# Adiciona possiveis caminhos de bibliotecas ao PATH
PATH=$PATH:/usr/local/bin

# Cria o diretório destino dos logs deste script
mkdir -p $LOG_FOLDERPATH

# Gera o nome do arquivo do log a partir do timestamp  
backup_file=$(date '+leggo_data_''%d_%m_%Y_%H_%M_%S')
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
       -a $EXPORT_FOLDERPATH/autores_leggo.csv \
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

fetch_leggo_autores() {

pprint "Baixando e exportando novos dados de autores das proposições monitoradas."
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -a $EXPORT_FOLDERPATH/autores_leggo.csv \
       -p $PLS_FILEPATH \
       -e $EXPORT_FOLDERPATH \
       -f 5
check_errs $? "Não foi possível baixar dados de autores das proposições monitoradas."   

}

fetch_leggo_relatores() {

pprint "Baixando e exportando novos dados de relatores das proposições monitoradas."
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/fetch_updated_bills_data.R \
       -p $PLS_FILEPATH \
       -o $EXPORT_FOLDERPATH/proposicoes.csv \
       -e $EXPORT_FOLDERPATH \
       -f 6
check_errs $? "Não foi possível baixar dados de relatores das proposições monitoradas."   

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

generate_backup(){

pprint "Gerando backup dos csvs"
       mkdir -p ${BACKUP_FOLDERPATH}${backup_file}
       docker run -d --rm -it --name alpine --mount type=volume,source=leggo_data,target=/data alpine
       list_csv=( 
       alpine:/data/camara 
       alpine:/data/senado 
       alpine:/data/pops 
       alpine:/data/proposicoes.csv 
       alpine:/data/coautorias_edges.csv 
       alpine:/data/coautorias_nodes.csv 
       alpine:/data/trams.csv 
       alpine:/data/hists_temperatura.csv 
       alpine:/data/autorias.csv 
       alpine:/data/pautas.csv 
       alpine:/data/progressos.csv 
       alpine:/data/emendas.csv 
       alpine:/data/atuacao.csv 
       alpine:/data/comissoes.csv 
       alpine:/data/pressao.csv 
       alpine:/data/anotacoes_especificas.csv 
       alpine:/data/interesses.csv 
       alpine:/data/anotacoes_gerais.csv 
       alpine:/data/entidades.csv 
       alpine:/data/autores_leggo.csv 
       alpine:/data/relatores_leggo.csv
       alpine:/data/proposicoes_destaques.csv
       alpine:/data/governismo.csv
       alpine:/data/disciplina.csv
       alpine:/data/votacoes_sumarizadas.csv
       alpine:/data/props_apensadas.csv
       alpine:/data/props_apensadas_nao_monitoradas.csv
       )
       for index in ${list_csv[@]}; do 
              docker cp $index ${BACKUP_FOLDERPATH}${backup_file}
       done
       docker stop alpine
       check_errs $? "Não foi possível criar a pasta de backup."
}

keep_last_backups() {
pprint "Mantendo apenas os últimos backups gerados"
       backups_to_keep=7
       ls -lt ${BACKUP_FOLDERPATH} | grep ^d | tail -n +$(($backups_to_keep + 1)) | awk '{print $9}' | while IFS= read -r f; do
              pprint $'Removendo '${BACKUP_FOLDERPATH}$f
              rm -rf ${BACKUP_FOLDERPATH}$f
       done
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
       -o $EXPORT_FOLDERPATH \
       -e $EXPORT_FOLDERPATH/entidades.csv
check_errs $? "Não foi possível processar dados dos documentos baixados."

}

process_governismo() {

pprint "Processando dados de Governismo"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/governismo/export_governismo.R \
       -v $EXPORT_FOLDERPATH/votos.csv \
       -p $EXPORT_FOLDERPATH/votacoes.csv \
       -i "2019-02-01" \
       -f "2022-12-31" \
       -e $EXPORT_FOLDERPATH/governismo.csv
check_errs $? "Não foi possível processar dados de Governismo"

}

process_disciplina() {

pprint "Processando dados de Disciplina"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/disciplina/export_disciplina.R \
       -v $EXPORT_FOLDERPATH/votos.csv \
       -o $EXPORT_FOLDERPATH/orientacoes.csv \
       -p $EXPORT_FOLDERPATH/votacoes.csv \
       -i "2019-02-01" \
       -f "2022-12-31" \
       -e $EXPORT_FOLDERPATH/disciplina.csv
check_errs $? "Não foi possível processar dados de Disciplina"

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
       -a leggo_data/apelidos.csv 
check_errs $? "Não foi possível gerar os dados de apelidos das proposições."

pprint "Gerando dados de pressão do Google Trends"
docker-compose -f $LEGGOTRENDS_FOLDERPATH/docker-compose.yml run --rm leggo-trends \
       python3 fetch_google_trends.py \
       leggo_data/apelidos.csv \
       leggo_data/pops/ \
       leggo_data/pops_backups/ \
       configuration.env
check_errs $? "Não foi possível baixar dados de pressão pelo Google Trends."

# pprint "Gerando dados de popularidade do Twitter"
# docker-compose -f $LEGGOTRENDS_FOLDERPATH/docker-compose.yml \
#       run --rm leggo-trends \
#       Rscript scripts/tweets_from_last_days/export_tweets_from_last_days.R \
#       -a leggo_data/apelidos.csv \
#       -o leggo_data/ 
# check_errs $? "Não foi possível baixar dados de pressão pelo Twitter."

pprint "Gerando índice de popularidade combinando Twitter e Google Trends"
docker-compose -f $LEGGOTRENDS_FOLDERPATH/docker-compose.yml run --rm leggo-trends \
      Rscript scripts/popularity/export_popularity.R \
      -t leggo_data/trends.csv \
      -g leggo_data/pops \
      -i leggo_data/interesses.csv \
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
check_errs $? "Não foi possível atualizar os dados de parlamentares"
} 

process_entidades() {
pprint "Processa dados de entidades"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/entidades/export_entidades.R \
       -p $EXPORT_FOLDERPATH/parlamentares.csv \
       -o $EXPORT_FOLDERPATH
check_errs $? "Não foi possível processar os dados de entidades"
} 

process_criterios () {
pprint "Processa criterios de proposições em destaque"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/proposicoes/destaques/export_destaques.R \
       -p $EXPORT_FOLDERPATH/proposicoes.csv \
       -t $EXPORT_FOLDERPATH/progressos.csv \
       -r $EXPORT_FOLDERPATH/trams.csv \
       -i $EXPORT_FOLDERPATH/interesses.csv \
       -s $EXPORT_FOLDERPATH/pressao.csv \
       -e $EXPORT_FOLDERPATH/proposicoes_destaques.csv
check_errs $? "Não foi possível processar os dados de criterios de destaque"
}

process_props_apensadas() {
pprint "Processa proposições apensadas"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/proposicoes/apensadas/export_apensadas.R \
       -p $EXPORT_FOLDERPATH/proposicoes.csv \
       -i $EXPORT_FOLDERPATH/interesses.csv \
       -o $EXPORT_FOLDERPATH
check_errs $? "Não foi possível processar os dados de proposições apensadas"
}

process_votos () {
  pprint "Atualiza e processa dados de votos"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/votos/export_votos.R \
       -v $EXPORT_FOLDERPATH/votacoes.csv \
       -u $EXPORT_FOLDERPATH/votos.csv \
       -p $EXPORT_FOLDERPATH/proposicoes.csv \
       -e $EXPORT_FOLDERPATH/entidades.csv
check_errs $? "Não foi possível atualizar e processar os dados de votos"
     
}

process_orientacoes (){
       pprint "Atualiza e processa dados de orientações"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/orientacoes/export_orientacoes.R \
       -v $EXPORT_FOLDERPATH/votacoes.csv \
       -u $EXPORT_FOLDERPATH/votos.csv \
       -o $EXPORT_FOLDERPATH/orientacoes.csv
check_errs $? "Não foi possível atualizar e processar os dados de orientações"
}

process_votacoes_sumarizadas() {

pprint "Processando dados de Votações sumarizadas"
docker-compose -f $LEGGOR_FOLDERPATH/docker-compose.yml run --rm rmod \
       Rscript scripts/votacoes_sumarizadas/export_votacoes_sumarizadas.R \
       -v $EXPORT_FOLDERPATH/votos.csv \
       -o $EXPORT_FOLDERPATH/orientacoes.csv \
       -p $EXPORT_FOLDERPATH/votacoes.csv \
       -i "2019-02-01" \
       -f "2022-12-31" \
       -e $EXPORT_FOLDERPATH/votacoes_sumarizadas.csv
check_errs $? "Não foi possível processar dados de Votações sumarizadas"

}

process_twitter() {
       env=$1
       pprint "Processa os dados de tweets"

       if [ $env == "development" ]
       then
              echo "Processando dados no ambiente de desenvolvimento"
              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/docker-compose.override.yml \
                     run --rm r-twitter-service \
                     Rscript code/export_data.R \
                     -u $URL_API_PARLAMETRIA

              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/docker-compose.override.yml \
                     run --rm r-twitter-service \
                     Rscript code/processor/export_data_to_db_format.R
       elif [ $env == "production" ]
       then
              echo "Processando dados no ambiente de produção"

              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/prod.yml \
                     build

              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/prod.yml \
                     run --rm r-twitter-service \
                     Rscript code/export_data.R \
                     -u $URL_API_PARLAMETRIA

              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/prod.yml \
                     run --rm r-twitter-service \
                     Rscript code/processor/export_data_to_db_format.R
       else
              echo "Tipo de atualização inválido. As opções são 'development', 'production'."
       fi
}

update_db_twitter() {
       env=$1

       pprint "Atualiza banco de dados do Twitter"

       if [ $env == "development" ]
       then
              echo "Atualizando BD de desenvolvimento"
              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/docker-compose.override.yml \
                     run --no-deps --rm feed sh -c "python manage.py do-migrations && python manage.py update-data"
       elif [ $env == "staging" ]
       then
              echo "Atualizando BD Staging"
              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/staging.yml \
                     build

              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/staging.yml \
                     run --no-deps --rm feed sh -c "python manage.py do-migrations && python manage.py update-data"
       elif [ $env == "production" ]
       then
              echo "Atualizando BD Production"
              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/prod.yml \
                     build

              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/prod.yml \
                     run --no-deps --rm feed sh -c "python manage.py do-migrations && python manage.py update-data"
       else
              echo "Tipo de atualização inválido. As opções são 'development', 'staging', 'production'."
       fi
}

create_schema_tweets() {
       pprint "Criando tabelas da atualização dos tweets"
       docker-compose -f $LEGGOTWITTERDADOS_FOLDERPATH/docker-compose.yml \
       -f $LEGGOTWITTERDADOS_FOLDERPATH/docker-compose.override.yml \
       run --no-deps --rm crawler-twitter-service \
       sh -c "python manage.py create-schema" \
       check_errs $? "Não foi possível criar as tabelas de atualização dos tweets."
}

process_tweets() {
       pprint "Processando tweets por username"
       docker-compose -f $LEGGOTWITTERDADOS_FOLDERPATH/docker-compose.yml \
       -f $LEGGOTWITTERDADOS_FOLDERPATH/docker-compose.override.yml \
       run --no-deps --rm crawler-twitter-service \
       sh -c "python manage.py process-tweets -l 'https://docs.google.com/spreadsheets/d/e/2PACX-1vR1Dh6vN_cCzpPqtY1nfZU90W5nghlesAFAE3-uqMgw8tOn0UpKJjW-eNd_g-BAs-nhrXLBTDCL8IvJ/pub?gid=0&single=true&output=csv'" \
       check_errs $? "Não foi possível processar os tweets."
}

reset_db_twitter() {
       env=$1

       pprint "Reseta banco de dados do Twitter e aplica as migrations"

       if [ $env == "development" ]
       then
              echo "Atualizando BD de desenvolvimento"
              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/docker-compose.override.yml \
                     run --no-deps --rm feed sh -c "python manage.py drop-tables --drop true \
                     && python manage.py create-tables && python manage.py do-migrations"
       elif [ $env == "staging" ]
       then
              echo "Atualizando BD Staging"
              
              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/staging.yml \
                     build

              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/staging.yml \
                     run --no-deps --rm feed sh -c "python manage.py drop-tables --drop true \
                     && python manage.py create-tables && python manage.py do-migrations"
       elif [ $env == "production" ]
       then
              echo "Atualizando BD Production"
       
              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/prod.yml \
                     build
              
              docker-compose -f $LEGGOTWITTER_FOLDERPATH/docker-compose.yml \
                     -f $LEGGOTWITTER_FOLDERPATH/deploy/prod.yml \
                     run --no-deps --rm feed sh -c "python manage.py drop-tables --drop true \
                     && python manage.py create-tables && python manage.py do-migrations"
       else
              echo "Tipo de atualização inválido. As opções são 'development', 'staging', 'production'."
       fi
}

run_pipeline_votacoes() {

       pprint "Atualizando Dados de Votações, votos, governismo e disciplina"

       # Build do leggoR
       build_leggor

       # Processa dados de votações e votos na legislatura atual
       process_votos

       # Calcula o governismo com base nos votos nominais dos parlamentares
       process_governismo

       # Calcula os dados de orientações na Câmara e Senado
       process_orientacoes
       
       # Calcula a Disciplina Partidária com base nos votos nominais dos parlamentares
       process_disciplina

       # Processa dados sumarizados de votações por parlamentar
       process_votacoes_sumarizadas

}

run_pipeline_leggo_content() {
       #Build container with current codebase
       build_leggo_content

       # Analyze text
       process_leggo_content

       #Aggregate emendas distances
       update_distancias_emendas
}

run_pipeline() {
       run_analise_emendas=$1

	#Build container with current codebase
	build_leggor

       #Setup volume of leggo data
       setup_leggo_data_volume

       #Process entities
       process_entidades

       #Process pls_interesse
       processa_pls_interesse

       #Fetch and Process Prop metadata and tramitação
       fetch_leggo_props

       #Fetch and Process data from authors of bills
       fetch_leggo_autores

       #Fetch and Process data from authors of bills
       fetch_leggo_relatores

       #Fetch and Process interests
       processa_interesses

       #Process appended propositions
       process_props_apensadas

       # Fetch and Process anotações
       process_anotacoes

	#Fetch related documents
	update_leggo_data

       #processa criterios 
       process_criterios

	#Process related documents
	process_leggo_data

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
    printf "\t-fetch-autores: Baixa dados dos relatores das proposições\n"   
    printf "\t-fetch-relatores: Baixa dados dos autores das proposições\n" 
    printf "\t-fetch-props: Baixa dados de proposições\n"
    printf "\t-fetch-emendas: Baixa dados de emendas\n"
    printf "\t-fetch-comissoes: Baixa dados de comissões\n"
    printf "\t-update-emendas: Atualiza dados de emendas com distâncias atualizadas\n"
    printf "\t-update-db-dev: Importa dados atualizados para o Banco de Dados do Backend Dev\n"
    printf "\t-update-db-prod: Importa dados atualizados para o Banco de Dados do Backend Prod\n"
    printf "\t-run-basic-pipeline: Roda pipeline básico de atualização de dados do Leggo (sem análise de emendas)\n"
    printf "\t-run-full-pipeline: Roda pipeline completo de atualização de dados do Leggo\n"
    printf "\t-run-pipeline-leggo-content: Roda pipeline para análise das Emendas\n"
    printf "\t-run-pipeline-votacoes: Roda pipeline para captura e processamento de Votações, votos, governismo e disciplina\n"
    printf "\t-process-leggo-twitter <env>: Processa dados de tweets. <env> pode ser: 'development', production'.\n"
    printf "\t-update-db-twitter <env>: Atualiza dados do BD do leggo-twitter. <env> pode ser: 'development', 'staging', production'.\n"
    printf "\t-reset-db-twitter <env>: Reseta o BD do leggo-twitter. <env> pode ser: 'development', 'staging', production'.\n"
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
    printf "\t-process-entidades: Processa dados de entidades\n"
    printf "\t-generate-backup: Gera pasta com backup dos csvs\n"
    printf "\t-keep-last-backups: Mantém apenas um número fixo de backups armazenados\n"
    printf "\t-process-criterios: Processa critérios\n"
    printf "\t-process-votos: Atualiza e processa dados de votos\n"
    printf "\t-process-orientacoes: Atualiza e processa dados de orientacoes\n"
    printf "\t-process-governismo: Processa dados de governismo\n"
    printf "\t-process-disciplina: Processa dados de disciplina partidária\n"
    printf "\t-process-votacoes-sumarizadas: Processa dados de votações sumarizadas\n"
    printf "\t-setup-leggo-data-volume: Configura volume leggo_data\n"
    printf "\t-process-apensadas: Processa dados de proposições apensadas\n"
    printf "\t-create-schema-tweets: Cria tabelas que possibilitam a atualização dos tweets\n"
    printf "\t-process-tweets: Processa e atualiza dados de tweets\n"
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

if [[ $@ == *'processa-interesses'* ]]; then processa_interesses
fi

if [[ $@ == *'-fetch-data'* ]]; then fetch_leggo_data
fi

if [[ $@ == *'-fetch-autores'* ]]; then fetch_leggo_autores
fi

if [[ $@ == *'-fetch-relatores'* ]]; then fetch_leggo_relatores
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

if [[ $@ == *'-run-pipeline-votacoes'* ]]; then run_pipeline_votacoes
fi

if [[ $@ == *'-process-leggo-twitter'* ]]; then process_twitter "$2"
fi

if [[ $@ == *'-update-db-twitter'* ]]; then update_db_twitter "$2"
fi

if [[ $@ == *'-reset-db-twitter'* ]]; then reset_db_twitter "$2"
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

if [[ $@ == *'-process-entidades'* ]]; then process_entidades
fi

if [[ $@ == *'-process-criterios'* ]]; then process_criterios
fi

if [[ $@ == *'-generate-backup'* ]]; then generate_backup
fi

if [[ $@ == *'-keep-last-backups'* ]]; then keep_last_backups
fi

if [[ $@ == *'-process-votos'* ]]; then process_votos
fi

if [[ $@ == *'-process-orientacoes'* ]]; then process_orientacoes
fi

if [[ $@ == *'-process-governismo'* ]]; then process_governismo
fi

if [[ $@ == *'-process-disciplina'* ]]; then process_disciplina
fi

if [[ $@ == *'-process-votacoes-sumarizadas'* ]]; then process_votacoes_sumarizadas
fi

if [[ $@ == *'-setup-leggo-data-volume'* ]]; then setup_leggo_data_volume
fi

if [[ $@ == *'-process-apensadas'* ]]; then process_props_apensadas
fi

if [[ $@ == *'-process-tweets'* ]]; then process_tweets
fi

if [[ $@ == *'-create-schema-tweets'* ]]; then create_schema_tweets
fi

# Registra a data final
date
pprint "Feito!"
