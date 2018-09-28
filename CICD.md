# Continuos Integration / Continuos Deploy (CI/CD)

Atualmente estamos usando Gitlab e [Portainer](https://github.com/portainer/portainer), em uma estrutura baseada nesse [artigo](https://medium.com/lucjuggery/even-the-smallest-side-project-deserves-its-ci-cd-pipeline-281f80f39fdf).

## Fluxo

1. Um commit é feito no Gitlab ou Github
2. Gitlab detecta o commit e passa para o runner fazer os testes
    1. Build de imagem de produção
    2. Teste da imagem de produção
3. Caso o commit tenha sido no master branch, o runner irá fazer o deploy
    1. Ativa webhook do serviço no Portainer
    2. Portainer baixa a nova imagem de produção e faz o deploy dela
    
## Notas gerais

### Gitlab Runner

Como os runners compartilhados do Gitlab são lentos, instalamos um no nosso próprio servidor.
Assim o Gitlab pode passar as tarefas de CI/CD para ele.

O fato do Runner estar rodando na nossa núvem permite que ele acesse o Portainer (também na nossa núvem) sem que esse último precise ser exposto para a internet.

### Portainer

O Portainer é útil por disponibilizar webhooks para atualizar as imagens e fazer o deploy delas.
Além disso ele permite listar os deploys feitos e revertê-los, além de permitir gerenciar quase tudo relativo ao Docker atráves de uma interface web. Inclusive acessar os containers via SSH pela própria interface web.

Rodamos o Portainer no modo Swarm (parece que só assim ele disponibiliza webhooks).
Nesse modo há 3 conceitos importantes:

- Stacks: definido por um `docker-compose.yml`, agrega um conjunto de services.
- Service: um item service descrito no `docker-compose.yml`, é uma container mais suas configurações, com volumes, nome da imagem, do container etc.
- Container: o container em si, que roda cada aplicação.

## Limitações

Atualizações no compose (stack) no Portainer precisam ser feitas manualmente (talvez seja possível usar a API dele para automatizar isso?).

---

## Passos

A seguir são listados os passos usados para configurar o sistema de CI/CD usado.
Eles podem ser úteis para reinstalar todo o sistema ou para adicionar um novo repositório à plataforma.

Os passos estão prescedidos de um identificador do local onde ele deve ser executado, facilitando visualizar quais passos precisam ser refeitos caso um dos módulos precise ser reinstalado ou configurado.

Identificadores:

- servidor: servidor usado para instalar o runner e hospedar a plataforma (incluindo o portainer); o runner pode estar em uma máquina diferente da plataforma
- gitlab/projeto: página do projeto no Gitlab
- local: máquina local da pessoa fazendo a configuração

### Gitlab Runner

- servidor: [instalar](https://docs.gitlab.com/runner/install/index.html) e [registrar](https://docs.gitlab.com/runner/register/index.html)
- gitlab/projeto: desativar runners compartilhados (os compartilhados são mais lentos e podem estar configurados diferente do nosso runner, fazendo o CI/CD se comportar de maneira não consistente)

### Portainer

- servidor: $ sudo docker swarm init
- servidor: https://portainer.readthedocs.io/en/latest/deployment.html#inside-a-swarm-cluster
- local: $ ssh -NL 8888:localhost:9000 <hostname>
- local: http://localhost:8888 e colocar senha
- local: http://localhost:8888/#/registries/new e colocar login gitlab ( registry.gitlab.com login e senha de usuário comum )
- portainer: criar uma stack agregando composes e copiando lá, adicionar envs para o que precisar
- gitlab/projeto: configurar em CI/CD uma DEPLOY_WEBHOOK com o webhook (lembrar de ver qual o IP:porta real que será usado pelo gitlab runner para acessar o Portainer )

### Extra

- gitlab/projeto: ajustar no README o caminho correto para as badges

