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
Rondando o Portainer no servidor:

```sh
$ sudo docker swarm init
```
> https://portainer.readthedocs.io/en/latest/deployment.html#inside-a-swarm-cluster

### Local
Para acessar o Portainer da sua máquina local e visualizar os serviços, você deve fazer um *ssh tunnel* com a máquina remota e direcionar para a porta para a máquina local, da seguinte maneira:
```
$ ssh -L 8888:localhost:9000 <hostname> <porta>
```
Após isso, acesse http://localhost:8888 e coloque o usuário e a senha correta.

### Uso

Para disponibiizar o front e back, é preciso criar stacks e colocar manualmente os compose, adiciona variáveis de ambiente se preciso.

Em cada stack terá uma **WEBHOOK**, é essa que usaremos na configuração do *CI/CD* do projeto para atualizar os stacks (lembrar de ver qual o IP:porta real que será usado pelo gitlab runner para acessar o Portainer).

## Limitações

Atualizações no compose (stack) no Portainer precisam ser feitas manualmente (talvez seja possível usar a API dele para automatizar isso?).

O LeggoR não está usando esse processo descrito acima.
Ele é testado pelo Gitlab, mas não é feita nem a geração de uma imagem Docker nova nem o deploy dela.
Esses dois passos são feitos pelo [script de atualização](https://github.com/analytics-ufcg/agora-digital-geral/blob/master/update.sh) dos dados.

Já o RCongresso está com um fluxo mais diferente ainda, nem usa o Gitlab e é testado pelo Travis.

## Hospedagem

### Motivação

Para explicar como está hospedado o código atualmente, acho importante mostrar por que não está de um jeito mais simples.

#### 0 - O mais simples

Talvez o jeito mais direto de rodar o código é usar o próprio servidor de desenvolvimento que vem com a ferramenta usada.
É o que fazemos no Django, por exemplo, com `./manage.py runserver`. Não precisa instalar mais nada e já dá para ver o site no navegador.
Normalmente ele abre na porta 8000, mas podemos configurar para abrir na porta 80, padrão HTTP.
A questão é que a porta 80 é restrita, então a aplicação teria que ser rodada como `root`...
Até daria para hospedar o site em produção simplesmente fazendo isso, mas, como devem imaginar, não é muito seguro ou robusto.

#### 1 - Docker

Para automatizar o processo de instalação das dependências e ter um ambiente padronizado, botamos o código em um Docker.
Mas isso certamente não resolve os problemas anteriores.

#### 2 - Melhorando a execução do código

O servidor de desenvolvimento (ex.: `./manage.py runserver`) não é adequado para o ambiente de produção.
Às vezes ele só consegue atender a um cliente por vez, é mais lento, e não tem uma preocupação muito grande com segurança.
Por isso se recomenda usar um servidor mais propício. No nosso caso, para a API em Python, estamos usando o uWSGI.

#### 3 - Reverse Proxy

Mesmo os servidores de execução do código próprios para produção, geralmente não devem ser expostos diretamente à internet.
O enfoque deles costuma ser executar o código de maneira eficiente, mas não lidar com todas as complexidades e vulnerabilidades do HTTP.
Por isso é importante colocar algum servidor de HTTP mais robusto na frente (ex.: Apache, Nginx), que atua de "reverse proxy".
É esse servidor que tem contato com o mundo externo (internet) e repassa a requisição para a aplicação, já protegendo de alguns tipos de ataques.

Os servidores HTTP mais robustos também permitem usar a porta 80 para múltiplas aplicações, diferenciando pelo domínio. Ex.:

- api.exemplo.com -> aplicação em Python na porta 5000 interna da máquina onde está rodando o uWSGI
- site.exemplo.com -> fornecer os arquivos estáticos da pasta `/srv/www/html/` (servidores de HTTP são muito mais rápidos para servir arquivos estáticos)

É importante usar a porta 80 para tudo porque essa é a porta padrão que o navegador espera acessar para se comunicar em HTTP.
Se sua aplicação estiver em outra porta, você terá que forçar ele usando algo como `http://exemplo.com:5000`, o que é meio chato e pode gerar problemas com alguns firewalls.

Esse "proxy" pode ser tanto para uma porta interna (ex.: `localhost:5000`) da máquina como para um socket Unix (ex.: `/opt/aplicacao/app.socket`),
que parece um arquivo, mas é um canal de comunicação.
A desvantagem das portas é que podem conflitar com portas de outras aplicações.

#### 4 - HTTPS

Assim como a porta 80 é usada para HTTP, para HTTPS o padrão é a 443.
Além de usar essa outra porta, será necessário ter um certificado.

Um jeito simples é gerar um certificado "auto-assinado", também chamado de "snake oil".
Como ele não foi emitido por uma autoridade certificadora, os navegadores vão mostrar aquelas telas "assustadoras" dizendo que há algo errado no seu site.
Esse tipo de certificado não garante que você é você, porque qualquer pessoa pode gerar um certificado auto-assinado para qualquer domínio.
Apesar disso, um certificado desse tipo já permite usar HTTPS e criptografar a comunicação, o que pode ser o bastante em alguns casos.

Na maioria dos casos você não vai querer assustar as pessoas, então usará uma certificadora.
A mais usada atualmente, por ser gratuita, sem fins lucrativos e com certificação automatizável, é a Let's Encrypt.
Existem vários clientes que implementam o protocolo deles permitindo automatizar a emissão dos certificados.
Isso é importante porque os certificados precisam ser renovados a cada 3 meses.
O cliente oficial é o [certbot](https://certbot.eff.org).
Dependendo da sua configuração, com um comando você consegue que ele emita o certificado e configure o seu servidor HTTP para usá-lo.
Um comando precisa ser adicionado ao cron para renovar o certificado periodicamente e reiniciar o servidor de HTTP para usar o novo certificado.

Uma vez configurado o HTTPS, geralmente é uma boa ideia encaminhar todo o tráfego HTTP da porta 80 para HTTPS na porta 443.
Isso evita que alguém logue no seu site via HTTP, não criptografado, podendo vazar a senha.

Existem muitos parâmetros para serem usados na configuração HTTPS do servidor.
A má configuração deles pode deixar a criptografia vulnerável.
Existem [ferramentas para testar](https://www.ssllabs.com/ssltest/) a qualidade dessas configurações.

#### 5 - Automatizando a configuração do proxy e do HTTPS

Até o passo anterior, cada vez que queríamos adicionar uma nova aplicação, precisávamos ir nos arquivos de configuração do servidor de HTTP e adicionar uma nova configuração.
Dizendo qual domínio novo apontaria para qual aplicação dentro da máquina.
Além disso, precisaríamos gerar um novo certificado, para o novo domínio.
Possivelmente um certificado que inclua os domínios antigos e mais o novo.
Isso tudo pode ser meio chato de fazer...
Aí que entram ferramentas que cuidem disso automaticamente.

Tendo em vista que estamos usando docker, poderíamos usar o [nginx-proxy](https://github.com/jwilder/nginx-proxy), que cuida de configurar o reverse proxy, ou seja:

- exemplo.com aponta para container_docker1
- api.exemplo.com aponta para container_docker2

E ainda o [docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion), que cuida de gerar os certificados para cada domínio usando o Let's Encrypt, configurar o HTTPS e renovar quando necessário.

No nosso caso acabamos optando por experimentar o Traefik.

#### Traefik

O [Traefik](https://traefik.io) foi feito para servir de meio de campo entre a internet e os múltiplos 
services/containers rodando no servidor.
Ele é um servidor de HTTP, como o Nginx, só que já vem embutido com as funcionalidades 
descritas acima (proxy e HTTPS automático).
Logo, desde que suas aplicações estejam rodando via Docker, o Traefik é tudo que você 
precisa para elas serem servidas em seus respectivos domínios e via HTTPS.
O Traefik também é rodado via Docker.

Essa [página](https://docs.traefik.io/basics) na documentação possui dois diagramas
que ajudam bastante a entender o funcionamento dele.
Que possui 3 elementos básicos:

- entrypoints: que seriam as portas
- frontends: que seriam os domínios
- backends: os containers que vão processar as requisições

Para dizer qual domínio deve servir qual container, se usam "labels" na descrição
dos serviços no próprio docker-compose/stack.
Por exemplo, `traefik.frontend.rule=Host:api.exemplo.com`, faz com que o que chegar ao 
domínio `api.exemplo.com` seja mandado para o container em que esse label foi definido.

A configuração dele é feita pelo arquivo `traefik.toml` e o certificado fica, geralmente 
no `acme.json`.

### Arquitetura Atual

O digrama abaixo representa a arquitetura atual, com todos os containers do Docker usados.
O Github deve estar mostrando como um PNG, mas quando clicado deve abrir um SVG,
onde os links (sublinhados) estarão clicáveis.

![diagrama com arquitetura](http://www.plantuml.com/plantuml/proxy?fmt=svg&src=https://raw.githubusercontent.com/analytics-ufcg/leggo-geral/master/diagrama.puml?cachebuster=7)

(*[código fonte do diagrama](https://github.com/analytics-ufcg/leggo-geral/blob/master/diagrama.puml)*)

Cada quadradinho amarelo dentro do quadrado maior `Docker` é um container do Docker.
A maioria roda permanentemente e é gerenciada pelo Portainer.
A exceção é o `leggor` que é ativado pelo `cron`, atualiza os dados, e depois volta 
a ficar inativo.

Os retângulos avermelhados, Stacks, são os Stacks do Docker, 
cada um descrito por um `docker-compose.yml` e que pode conter 
múltiplos services do Docker.
Cada service usa um container.

Os "cilindros" cinzas são volumes Docker.
O `statics` é usado para o `proxy` em Nginx conseguir servir os arquivos estáticos 
diretamente, uma vez que ele é muito mais eficiente para isso do que o uWSGI.
O `nginx config` para substituir as configurações padrões do Nginx na imagem do Nginx 
sem precisar gerar uma nova imagem.
