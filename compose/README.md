# Agregador de configs docker do projeto

Arquivos para rodar frontend e backend em conjunto.

Esses arquivos são úteis para contornar esse problema:
https://github.com/docker/compose/issues/3874

## Uso

Assumindo os repositórios do backend e frontend estejam dentro da mesma pasta deste repositório, é possivel rodar os comandos abaixo.

Obs: Dependendo da posição desses outros repositórios pode ser necessário ajustar os caminhos para eles. No caso do helper isso pode ser feito editando o arquivo `.env` (dentro do diretório `compose`).

### Com helper

Desenvolvimento:
Exemplo
```
python3.6 ./run dev up
```
Produção:
Exemplo
```
python3.6 ./run prod up
```

Você pode executar também para qualquer versão do python acima da 3.6.

### Sem helper

Desenvolvimento:
```
docker-compose -f docker-compose.yml -f ../agora-digital-web/docker-compose.yml -f ../agora-digital-backend/docker-compose.yml -f ../agora-digital-backend/docker-compose.override.yml up
```
Produção:
```
docker-compose -f docker-compose.yml -f ../agora-digital-web/deploy/prod.yml -f ../agora-digital-backend/docker-compose.yml -f ../agora-digital-backend/deploy/prod.yml up
```

## Portainer
Para ajudar a gerenciar os containers rodados, você pode usar o Portainer e sua interface Web para gerenciar tudo do docker na sua máquina.

Para usá-lo:
```sh
docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
```
Após isso acesse http://localhost:9000 

## Limitações

**Build a partir desse compose não foi testado. É possível que não leve em consideração os `.dockerignore`, logo não seria recomendado.**
