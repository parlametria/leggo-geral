# Leggo - Documentação geral

Repositório para documentação e ferramentas de uso geral do projeto.

- [Rodar Aplicação Leggo localmente](compose/README.md)

## Como executar a captura dos dados através do Módulo de Dados

O script `update_leggo_data.sh` possui as funções necessárias para realizar a captura e atualização de todos os dados obtidos e capturados pelo módulo de dados.
Para que o script funcione corretamente, os seguintes repositórios devem ser clonados dentro de uma mesma pasta raiz, cujo caminho será passado como variável de ambiente:

- [leggoR](https://github.com/parlametria/leggoR)
- [leggoTrends](https://github.com/parlametria/leggoTrends)
- [versoes-de-proposicoes](https://github.com/parlametria/versoes-de-proposicoes) (deprecated)
- [leggo-content](https://github.com/parlametria/leggo-content) (deprecated)
- [leggo-twitter-dados](https://github.com/parlametria/leggo-twitter-dados)

Além disso, o repositório [`rcongresso`](https://github.com/analytics-ufcg/rcongresso) deve ser clonado dentro da pasta do leggoR para ser usado no build do pacote R.

### Passo 1
Para executá-lo é preciso configurar as variáveis de ambiente por ele utilizadas. Para isto, **crie uma cópia do arquivo .env.sample** e o renomeie para `.env`. Em seguida preencha as variáveis com os valores adequados para execução.

- ***URL_INTERESSES***: URL para planilha com lista de interesses analisados pelo Leggo. Consulte um membro da equipe para obter essa URL. 
Exemplo: URL_INTERESSES="<url_para_planilha>"

- ***PLS_FILEPATH***: caminho para o arquivo csv com a lista de Proposições que irão ter seus dados capturados e processados. Esse caminho é referenciado dentro do container rmod e por este motivo geralmente está ligado ao diretório `leggo_data`. 
Exemplo: PLS_FILEPATH=./leggo_data/tabela_geral_ids_casa_new.csv ou PLS_FILEPATH=./leggo_data/pls_interesses.csv (caso você queira capturar todos os interesses).

- ***WORKSPACE_FOLDERPATH***: caminho para a pasta base do workspace (onde os repositórios estão clonados). Esse é o diretório a partir do qual o script de update vai rodar os comandos.
Exemplo: WORKSPACE_FOLDERPATH=../

- ***EXPORT_FOLDERPATH***: caminho para a saída dos dados processados pelo módulo de dados. Esse caminho é referenciado dentro do container rmod e por este motivo geralmente está ligado ao diretório `leggo_data`. 
Exemplo: EXPORT_FOLDERPATH=./leggo_data

- ***LEGGOR_FOLDERPATH***: caminho para o diretório que contém o código do repositório leggoR. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOR_FOLDERPATH=./leggoR

- ***LEGGOTRENDS_FOLDERPATH***: caminho para o diretório que contém o código do repositório leggoTrends. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOTRENDS_FOLDERPATH=./leggoTrends

- ***VERSOESPROPS_FOLDERPATH***: caminho para o diretório que contém o código do repositório versoes-de-proposicoes. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: VERSOESPROPS_FOLDERPATH=./versoes-de-proposicoes

- ***LEGGOCONTENT_FOLDERPATH***: caminho para o diretório que contém o código do repositório leggo-content. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOCONTENT_FOLDERPATH=./leggo-content

- ***LEGGOTWITTER_FOLDERPATH***: caminho para o diretório que contém o código do repositório leggo-twitter-dados. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOTWITTER_FOLDERPATH=./leggo-twitter-dados

- ***LOG_FOLDERPATH***: caminho para o arquivo de log a ser escrito durante a execução do pipeline de processamento dos dados.
Exemplo: LOG_FILEPATH=./logs/

- ***PROD_BACK_APP***: nome da aplicação do backend na versão de produção no Heroku.
Exemplo: PROD_BACK_APP=production_app_name

- ***DEV_BACK_APP***: nome da aplicação do backend na versão de desenvolvimento no Heroku.
Exemplo: DEV_BACK_APP=development_app_name

- ***BACKUP_FOLDERPATH***: caminho para o diretório onde são armazenados os arquivos de backup dos dados.
Exemplo: BACKUP_FOLDERPATH=./backups/

- ***URL_TWITTER_API***: Endereço da URL da API do [leggo twitter]("https://github.com/parlametria/leggo-twitter).
Exemplo: URL_TWITTER_API="https://leggo-twitter.herokuapp.com/api"

- ***URL_USERNAMES_TWITTER***: URL para lista de usernames para a recuperação e processamentos dos tweets
Exemplo: URL_USERNAMES_TWITTER="https://docs.google.com/spreadsheets/d/e/2PACX-1vR1Dh6vN_cCzpPqtY1nfZU90W5nghlesAFAE3-uqMgw8tOn0UpKJjW-eNd_g-BAs-nhrXLBTDCL8IvJ/pub?gid=0&single=true&output=csv"

### Passo 2

Uma vez configuradas as variáveis de ambiente, é possível verificar que procedimentos podem ser executados pelo `update_leggo_data` acessando o help do mesmo:

```
./update_leggo_data.sh -help
```
Olhe com cuidado para todos os roteiros que podem ser executados.

Para executar o pipeline principal com a atualização completa de todos os dados para as proposições de interesse execute:

```
./update_leggo_data.sh -run-full-pipeline
```

Atente que dependendo do número de proposições de interesse esse passo pode demorar um tempo considerável.

