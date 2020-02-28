# Leggo - Documentação geral

Repositórios para documentações e ferramentas para uso geral do projeto.

- [Compose Frontend + Backend](compose)
- [Documentação da Arquitetura](arquitetura.md)

## Como executar a captura dos dados através do Módulo de Dados

O script `update_leggo_data.sh` possui as funções necessárias para realizar a captura e atualização de todos os dados obtidos e capturados pelo módulo de dados.

### Passo 1
Para executá-lo é preciso configurar as variáveis de ambiente por ele utilizadas. Para isto, **crie uma cópia do arquivo .env.sample** e o renomeie para `.env`. Em seguida preencha as variáveis com os valores adequados para execução.

- ***PLS_FILEPATH***: caminho para o arquivo csv com a lista de Proposições que irão ter seus dados capturados e processados. Esse caminho é referenciado dentro do container rmod e por este motivo geralmente está ligado ao diretório `leggo_data`. 
Exemplo: PLS_FILEPATH=./leggo_data/tabela_geral_ids_casa_new.csv

- ***EXPORT_FOLDERPATH***: caminho para a saída dos dados processados pelo módulo de dados. Esse caminho é referenciado dentro do container rmod e por este motivo geralmente está ligado ao diretório `leggo_data`. 
Exemplo: EXPORT_FOLDERPATH=./leggo_data

- ***LEGGOR_FOLDERPATH***: caminho para o diretório que contém o código do repositório leggoR. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOR_FOLDERPATH=../leggoR

- ***LEGGOTRENDS_COMPOSE_FILEPATH***: caminho para o arquivo docker-compose.yml do repositório do LeggoTrends. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOTRENDS_COMPOSE_FILEPATH=../leggoTrends/docker-compose.yml

- ***VERSOESPROPS_COMPOSE_FILEPATH***: caminho para o arquivo docker-compose.yml do repositório do versoes-de-proposicoes. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: VERSOESPROPS_COMPOSE_FILEPATH=../versoes-de-proposicoes/docker-compose.yml

- ***LEGGOCONTENT_COMPOSE_FILEPATH***: caminho para o arquivo docker-compose.yml do repositório do leggo-content. Este caminho é referenciado na máquina local e portanto pode ser relativo ou absoluto a mesma.
Exemplo: LEGGOCONTENT_COMPOSE_FILEPATH=../leggo-content/docker-compose.yml

- ***LOG_FILEPATH***: caminho para o arquivo de log a ser escrito durante a execução do pipeline de processamento dos dados.
Exemplo: LOG_FILEPATH=/tmp/update_leggo_data.log

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

