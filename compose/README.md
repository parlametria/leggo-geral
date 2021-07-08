# Orquestrador de composes do Leggo

Este orquestrador permite que o ambiente de desenvolvimento seja executado considerando todos os módulos a nível de aplicação:
banco de dados (leggo_data, leggo_twitter), backend(leggo-backend, leggo-twitter) e frontend(leggo-painel).

## Comece por aqui

Se esta for a sua primeira execução, recomendamos que:

 1. Baixe os repositórios necessários;
 2. Execute o `build-painel` usando o make;
 3. [Crie as tabelas do leggo-twiiter-dados](https://github.com/parlametria/leggo-geral/wiki/leggo-twitter-dados).

## Como usar:

### 1. Baixe os repositórios necessários

Você deve ter clonado os repositórios dentro do mesmo diretório que também contém este repositório do leggo-geral. 

Obs: Dependendo da posição desses outros repositórios pode ser necessário ajustar os caminhos para eles. No caso do helper isso pode ser feito editando o arquivo `.env` (dentro do diretório `compose`).

Os repositórios que devem ser baixados são:
- [leggo-twitter-dados](https://github.com/parlametria/leggo-twitter-dados)
- [leggo-twitter](https://github.com/parlametria/leggo-twitter)
- [leggo-backend](https://github.com/parlametria/leggo-backend)
- [leggo-frontend](https://github.com/parlametria/leggo-frontend) (deprecated)
- [leggo-painel](https://github.com/parlametria/leggo-painel)

Atenção: Leia o README do [leggo-backend](https://github.com/parlametria/leggo-backend) para a configuração correta das variáveis de ambiente necessárias para a execução da API.

leggo-frontend é a versão do frontend escrita em Vue e não é mais continuada pelo Parlametria. Já o leggo-painel é a versão do frontend escrita em Angular.

Existem duas stacks possíveis para execução:
- `painel` : executa todos os containers necessários para o Painel ser acessado;
- `twitter-dados`: executa apenas o módulo do leggo-twitter-dados


### 2. Execute o build dos containers

#### Com make

Temos alguns comandos definidos que podem facilitar caso seja a sua primeira execução ou deseje apenas gerenciar os containers que levantam o `painel`. As opções são:

 - **`help`**: Mostra a mensagem de ajuda
 - **`build-painel`**: Contrói todos os volumes e containers necessários. Recomendado para primeira execução.
- **`build-no-cache-painel`**: Contrói todos os volumes e containers necessários sem cache.
- **`up-painel`**: Levanta todos os containers do Painel.
- **`down-volumes-painel`**: Apaga todos os containers, incluindo volumes


#### Exemplo de chamada
Estando neste diretório é possível executar:

```
make build-painel
```

#### Com helper

De dentro do diretório `compose` é possível executar:

#### Painel (backend + frontend Angular)
```
python3.6 run painel up
```
A API estará disponível em http://localhost:8000/.
O frontend estará disponível em http://localhost:4200/.

#### Twitter-dados (banco PostgreSQL)
```
python3.6 run twitter-dados up
```
O banco estará disponível no host, user, database e senha setados no arquivo .env do leggo-twitter-dados.

**Você pode executar também para qualquer versão do python acima da 3.6. Caso você não a tenha instalada na sua máquina.**

#### **Configuração de volumes**
Se ao levantar os serviços usando o leggo-geral o seguinte erro for encontrado:
```sh
ERROR: Volume backup_data declared as external, but could not be found. Please create the volume manually using `docker volume create --name=backup_data` and try again.
```
Então execute em um terminal local: `docker volume create --name=backup_data`.

O mesmo vale para o volume leggo_data.

#### Sem helper

De dentro do diretório `compose` é possível executar (apesar de não ser recomendado):

##### Painel:
```
docker-compose -f docker-compose.yml -f ../../leggo-painel/docker-compose.yml -f ../../leggo-backend/docker-compose.yml -f ../../leggo-backend/docker-compose.override.yml -f ../../leggo-twitter-dados/docker-compose.yml -f ../../leggo-twitter/docker-compose.yml -f ../../leggo-twitter-dados/docker-compose.override.yml up
```

##### Twitter-dados:
```
docker-compose -f docker-compose.yml -f ../../leggo-twitter-dados/docker-compose.yml -f ../../leggo-twitter-dados/docker-compose.override.yml up
```

### Comandos úteis

Nos exemplos anteriores o comando `up` foi o utilizado para executar os serviços dos diferentes repositórios. Mas este orquestrador permite também que outros comandos do docker-compose possam ser executados.

Um comando que deve ser usado com cuidado é aquele que para os serviços e apaga os volumes criados. Isto significa que o banco de dados local será apagado. Para executar este comando:

```
python3.6 run <stack> down --volumes
```
\<stack\> deve ser painel ou twitter-dados.

Também é possível realizar o build de todos os serviços:
```
python3.6 run <stack> build
```
\<stack\> deve ser painel ou twitter-dados.

Ou ainda executar um build sem cache (pode demorar bastante devido a instalação de todas as depedências):
```
python3.6 run <stack> build --no-cache
```
\<stack\> deve ser painel ou twitter-dados.

Para saber a lista completa de comandos do docker-compose execute:
`docker-compose help`

Outros comandos úteis são os de abrir o shell dentro do container em execução:

Para isto verifique quais os containers em execução:
```
docker ps
```

Agora você pode entrar em qualquer container fazendo:
```
$ docker exec -it agorapi sh
ou
$ docker exec -it dbapi sh
ou
$ docker exec -it frontend_painel_dev sh
ou
$ docker exec -it postgres-leggo-twitter sh
```
Um terminal shell dentro do container correspondente abrirá.

Qualquer dúvida, bug ou sugestão entre em [contato](https://github.com/parlametria/leggo-geral/pulls).


### Portainer (deprecated)
Para ajudar a gerenciar os containers rodados, você pode usar o Portainer e sua interface Web para gerenciar tudo do docker na sua máquina.

Para usá-lo:
```sh
docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
```
Após isso acesse http://localhost:9000 

### Limitações

**Build a partir desse compose não foi testado. É possível que não leve em consideração os `.dockerignore`, logo não seria recomendado.**
