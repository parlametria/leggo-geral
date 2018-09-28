# Agregador de configs docker do projeto

Arquivos para rodar frontend e backend em conjunto.

Esses arquivos são úteis para contornar esse problema:
https://github.com/docker/compose/issues/3874

## Uso

Asumindo os repositórios do backend e frontend ao lado deste repositório, rodar os comandos abaixo.
Dependendo da posição desses outros repositórios pode ser necessário ajustar os caminhos para eles. No caso do helper isso pode ser feito editando o arquivo `.env`.

### Com helper

Desenvolvimento:
```
./run dev up
```
Produção:
```
./run prod up
```

### Sem helper

Desenvolvimento:
```
docker-compose -f docker-compose.yml -f ../agora-digital-web/docker-compose.yml -f ../agora-digital-backend/docker-compose.yml -f ../agora-digital-backend/docker-compose.override.yml up
```
Produção:
```
docker-compose -f docker-compose.yml -f ../agora-digital-web/deploy/prod.yml -f ../agora-digital-backend/docker-compose.yml -f ../agora-digital-backend/deploy/prod.yml up
```

## Limitações

**Build a partir desse compose não foi testado. É possível que não leve em consideração os `.dockerignore`, logo não seria recomendado.**
