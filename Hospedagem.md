# Hospedagem

## Motivação

Para explicar como está hospedado o código atualmente, acho importante mostrar por que não está de um jeito mais simples.

### 0 - O mais simples

Talvez o jeito mais direto de rodar o código é usar o próprio servidor de desenvolvimento que vem com a ferramenta usada.
É o que fazemos no Django, por exemplo, com `./manage.py runserver`. Não precisa instalar mais nada e já dá para ver o site no navegador.
Normalmente ele abre na porta 8000, mas podemos configurar para abrir na porta 80, padrão HTTP.
A questão é que a porta 80 é restrita, então a aplicação teria que ser rodada como `root`...
Até daria para hospedar o site em produção simplesmente fazendo isso, mas, como devem imaginar, não é muito seguro ou robusto.

### 1 - Docker

Para automatizar o processo de instalação das dependências e ter um ambiente padronizado, botamos o código em um Docker.

### 2 - Melhorando a execução do código

O servidor de desenvolvimento (ex.: `./manage.py runserver`) não é adequado para o ambiente de produção.
Às vezes ele só consegue atender a um cliente por vez, é mais lento, e não tem uma preocupação muito grande com segurança.
Por isso se recomenda usar um servidor mais propício. No nosso caso, para a API em Python, estamos usando o uWSGI.

### 3 - Reverse Proxy

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

### 4 - HTTPS

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
O cliente oficial é esse: https://certbot.eff.org/
Dependendo da sua configuração, com um comando você consegue que ele emita o certificado e configure o seu servidor HTTP para usá-lo.
Um comando precisa ser adicionado ao cron para renovar o certificado periodicamente e reiniciar o servidor de HTTP para usar o novo certificado.

Uma vez configurado o HTTPS, geralmente é uma boa ideia encaminhar todo o tráfego HTTP da porta 80 para HTTPS na porta 443.
Isso evita que alguém logue no seu site via HTTP, não criptografado, podendo vazar a senha.

Existem muitos parâmetros para serem usados na configuração HTTPS do servidor.
A má configuração deles pode deixar a criptografia vulnerável.
Existem [ferramentas para testar](https://www.ssllabs.com/ssltest/) a qualidade dessas configurações.

### 5 - Automatizando a configuração do proxy e do HTTPS

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

No nosso caso acabamos optando por experimentar o [Traefik](https://traefik.io).
Ele é um servidor de HTTP, como o Nginx, só que já vem embutido com as funcionalidades descritas acima.
Logo, desde que suas aplicações estejam rodando via Docker, o Traefik é tudo que você precisa para elas serem servidas em seus respectivos domínios e via HTTPS.
O Traefik também é rodado via Docker.

Para dizer qual domínio deve servir qual container, se usam "labels" no próprio docker-compose.
Por exemplo, `traefik.frontend.rule=Host:api.exemplo.com`, faz com que o que chegar ao domínio `api.exemplo.com` seja mandado para o container em que esse label foi definido.

## Arquitetura Atual

![diagrama com arquitetura](http://www.plantuml.com/plantuml/proxy?fmt=svg&src=https://raw.githubusercontent.com/analytics-ufcg/leggo-geral/master/diagrama.puml)

Portainer só está gerenciando os fronts e o back, não o leggor
leggor roda via script
nem todos os volumes estão representados

## Traefik

