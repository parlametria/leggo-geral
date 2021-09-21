# Leggo - Documentação geral

Repositório para documentação e ferramentas de uso geral do projeto. Atualmente possui dois principais módulos:

- [1. Executar a captura de dados](https://github.com/parlametria/leggo-geral#como-executar-a-captura-dos-dados-atrav%C3%A9s-do-m%C3%B3dulo-de-dados)
- [2. Rodar aplicação Leggo localmente](compose/README.md)

Na [**wiki**](https://github.com/parlametria/leggo-geral/wiki) adicionamos algumas explicações sobre cada módulo.

## Visão geral dos repositórios utilizados

Abaixo levantamos uma descrição resumida sobre cada repositório utilizado pelo leggo-geral:

- [`leggoR`](https://github.com/parlametria/leggoR): Responsável por baixar dados das APIs da Câmara e Senado mais direcionados ao contexto do Painel (como proposições apensadas, por exemplo) e de outras bibliotecas R, como [rcongresso](https://github.com/analytics-ufcg/rcongresso) e [perfil-parlamentarR](https://github.com/parlametria/perfil-parlamentarR), além de processar os dados utilizados pela aplicação, como progresso, proposições em destaque, atuação, etc.

- [`rcongresso`](https://github.com/analytics-ufcg/rcongresso): Responsável por baixar os dados das APIs da Câmara e do Senado relacionados às proposições: autores, relatores, proposições, tramitações, agenda, etc. Deve ser clonado dentro da pasta do leggoR para ser usado no build do pacote R.

- [`leggoTrends`](https://github.com/parlametria/leggoTrends): Responsável por baixar os dados de atividade no twitter servidos pela API do [leggo-twitter](https://github.com/parlametria/leggo-twitter) e processá-los para gerar a pressão do Painel.

- [`leggo-twitter`](https://github.com/parlametria/leggo-twitter): Responsável por disponibilizar os dados processados pelo módulo do [leggo-twitter-dados](https://github.com/parlametria/leggo-twitter-dados) via API.

- [`leggo-twitter-dados`](https://github.com/parlametria/leggo-twitter-dados): Responsável por baixar os dados de tweets para um conjunto de usuários e processá-los, gerando um mapeamento de tweets sobre as proposições monitoradas (os dados das proposições são disponibilizadas pela API do [leggo-backend](https://github.com/parlametria/leggo-backend)). Este módulo também faz as atualizações no banco do leggo-twiiter.

- [`leggo-backend`](https://github.com/parlametria/leggo-backend): Responsável por atualizar os dados de proposições no banco de dados leggo e disponibilizar esses dados via API, que são utilizados tanto pelo [leggo-twitter-dados](https://github.com/parlametria/leggo-twitter-dados) quanto pelo [leggo-painel](https://github.com/parlametria/leggo-painel).

- [`leggo-painel`](https://github.com/parlametria/leggo-painel): Responsável pelo front-end da aplicação [Painel Parlametria](https://painel.parlametria.org.br/). Acessa as APIs do [leggo-backend](https://github.com/parlametria/leggo-backend), [leggo-twitter](https://github.com/parlametria/leggo-twitter) e [perfil-parlamentar](https://github.com/parlametria/perfil-parlamentar).


## 1. Como executar a captura dos dados através do Módulo de Dados

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

- ***URL_INTERESSES***: URL para planilha com lista de interesses analisados pelo Leggo. No sample temos uma versão dev desta planilha. 
Exemplo: URL_INTERESSES="https://docs.google.com/spreadsheets/d/e/2PACX-1vTOdLk1wxJsekjGF5alyD0AP25wVtpnq0QTy6IZTebY_WSiiAF6Any-_BWRTpcerTHHW4zJL3Y9hHpf/pub?gid=0&single=true&output=csv".

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

- ***VERSOESPROPS_FOLDERPATH*** (deprecated): caminho para o diretório que contém o código do repositório versoes-de-proposicoes. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: VERSOESPROPS_FOLDERPATH=./versoes-de-proposicoes

- ***LEGGOCONTENT_FOLDERPATH*** (deprecated): caminho para o diretório que contém o código do repositório leggo-content. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOCONTENT_FOLDERPATH=./leggo-content

- ***LEGGOTWITTER_FOLDERPATH***: caminho para o diretório que contém o código do repositório leggo-twitter-dados. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOTWITTER_FOLDERPATH=./leggo-twitter-dados

- ***LOG_FOLDERPATH***: caminho para o arquivo de log a ser escrito durante a execução do pipeline de processamento dos dados.
Exemplo: LOG_FILEPATH=./logs/

- ***BACKUP_FOLDERPATH***: caminho para o diretório onde são armazenados os arquivos de backup dos dados.
Exemplo: BACKUP_FOLDERPATH=./backups/

- ***PROD_BACK_APP***: nome da aplicação do backend na versão de produção no Heroku.
Exemplo: PROD_BACK_APP=production_app_name

- ***DEV_BACK_APP***: nome da aplicação do backend na versão de desenvolvimento no Heroku.
Exemplo: DEV_BACK_APP=development_app_name

- ***URL_LISTA_ANOTACOES***: URL ou caminho para os insights de especialistas sobre determinadas proposições. Abaixo temos um link para uma versão de teste.
Exemplo: URL_LISTA_ANOTACOES="https://docs.google.com/spreadsheets/d/e/2PACX-1vQIC9sm_jTojACKqzF17nPU8qiQRmWSeaKDOeRuxkLnhSZwOwdx0GpgGflpJigM3-N_KOPBz85-wR_u/pub?gid=0&single=true&output=csv"


- ***URL_TWITTER_API***: Endereço da URL da API do [leggo twitter]("https://github.com/parlametria/leggo-twitter).
Exemplo: URL_TWITTER_API="https://leggo-twitter.herokuapp.com/api"

- ***URL_API_PARLAMETRIA***: URL da API do painel Parlametria.
Exemplo: URL_API_PARLAMETRIA="https://api.leggo.org.br"

- ***URL_USERNAMES_TWITTER***: URL para lista de usernames para a recuperação e processamentos dos tweets
Exemplo: URL_USERNAMES_TWITTER="https://docs.google.com/spreadsheets/d/e/2PACX-1vR1Dh6vN_cCzpPqtY1nfZU90W5nghlesAFAE3-uqMgw8tOn0UpKJjW-eNd_g-BAs-nhrXLBTDCL8IvJ/pub?gid=0&single=true&output=csv"

### Passo 2

Uma vez configuradas as variáveis de ambiente, é possível verificar que procedimentos podem ser executados pelo `update_leggo_data` acessando o help do mesmo:

```
./update_leggo_data.sh -help
```
Olhe com cuidado para todos os roteiros que podem ser executados.

Para executar o pipeline principal com a atualização completa de todos os dados para as proposições de interesse (sem análise de emendas), execute:

```
./update_leggo_data.sh -run-basic-pipeline
```

Atente que dependendo do número de proposições de interesse esse passo pode demorar um tempo considerável.

