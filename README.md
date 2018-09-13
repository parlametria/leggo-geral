# Agregador de configs docker do projeto

Arquivos para rodar frontend e backend em conjunto.

Esse repositório é útil para contornar esse problema:
https://github.com/docker/compose/issues/3874

## Uso

Asumindo repositórios ao lado desse, rodar:

Desenvolvimento:
```
docker-compose -f docker-compose.yml -f ../agora-digital-web/docker-compose.yml -f ../agora-digital-backend/docker-compose.yml -f ../agora-digital-backend/docker-compose.override.yml up
```
Produção:
```
docker-compose -f docker-compose.yml -f ../agora-digital-web/deploy/prod.yml -f ../agora-digital-backend/docker-compose.yml -f ../agora-digital-backend/deploy/prod.yml up
```

Pode-se usar também o helper, ex.:

```
./run.sh dev up
```

**Build a partir desse compose não foi testado. É possível que não leve em consideração os `.dockerignore`, logo não seria recomendado.**
