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

## Como funciona
Para utilizar o serviço de Continuos Integration do *Gitlab*, criamos um `.gitlab-ci.yml` que define o que deve ser feito e configuramos para que o projeto utilize um Runner, que é o que irá os passos ditos no `.gitlab-ci.yml`. No `.gitlab-ci.yml` de cada projeto, geralmente terá definido os passos build, test e deploy.

O runner do nosso projeto está no nosso próprio servidor, o que permite que seja mais rápido para executar as tarefas e também para que possa acessar o Portainer direto sem precisar ser exposto pela internet. Para isso é usado o [docker-in-docker executor](https://docs.gitlab.com/ce/ci/docker/using_docker_build.html#use-docker-in-docker-executor) para isolar o ambiente *CI/CD* do ambiente do servidor.

Toda vez que um commit é feito no projeto, o *gitlab runner* faz um build da imagem docker de produção e a testa, se o commit tiver sido no master, o runner irá também executar o passo de deploy. Para fazer o deploy, o *gitlab runner* ativa o webhook do serviço(stack) no Portainer, que é o orquestrador do nosso serviço, ele baixa a nova imagem de produção e assim faz o deploy dela.

## Gitlab Runner

Gitlab Runner é usado para rodar os *Jobs*, sendo usado em conjunto com o *Gitlab CI*, podendo ser rodado dentro de containers ou no nosso próprio servidor.

Para configurar:

1. [Instalar](https://docs.gitlab.com/runner/install/index.html) no nosso servidor
2. [Registrar](https://docs.gitlab.com/runner/register/index.html) no gitlab
3. Desativar runners compartilhados, pois são mais lentos e são configurados de maneira diferente do nosso Runner.
4. Depois é só definir os Jobs no `.gitlab-ci.yml` 

## Portainer

O Portainer é útil por disponibilizar webhooks para atualizar as imagens e fazer o deploy delas.
Além disso ele permite listar os deploys feitos e revertê-los, além de permitir gerenciar quase tudo relativo ao Docker atráves de uma interface web. Inclusive acessar os containers via SSH pela própria interface web.

Rodamos o Portainer no modo Swarm (parece que só assim ele disponibiliza webhooks).
Nesse modo há 3 conceitos importantes:

- **Stacks**: definido por um `docker-compose.yml`, agrega um conjunto de services.
- **Service**: um item service descrito no `docker-compose.yml`, é uma container mais suas configurações, com volumes, nome da imagem, do container etc.
- **Container**: o container em si, que roda cada aplicação.

### Servidor
```sh
$ sudo docker swarm init
```
> https://portainer.readthedocs.io/en/latest/deployment.html#inside-a-swarm-cluster

### Local
Para acessar o portainer da sua máquina local e visualizar os serviços, você deve fazer um *ssh tunnel* com a máquina remota e direcionar para a porta para a máquina local, da seguinte maneira:
```
$ ssh -L 8888:localhost:9000 <hostname> <porta>
```
Após isso, acesse http://localhost:8888 e coloque o usuário e a senha correta.

### Uso

Para disponibiizar o front e back, é preciso criar stacks e colocar manualmente os compose, adiciona variáveis de ambiente se preciso.

Em cada stack terá uma **WEBHOOK**, é essa que usaremos na configuração do *CI/CD* do projeto para atualizar os stacks (lembrar de ver qual o IP:porta real que será usado pelo gitlab runner para acessar o Portainer).

### Limitações

Atualizações no compose (stack) no Portainer precisam ser feitas manualmente (talvez seja possível usar a API dele para automatizar isso?).

O LeggoR não está usando esse processo descrito acima.
Ele é testado pelo Gitlab, mas não é feita nem a geração de uma imagem Docker nova nem o deploy dela.
Esses dois passos são feitos pelo [script de atualização](https://github.com/analytics-ufcg/agora-digital-geral/blob/master/update.sh) dos dados.
