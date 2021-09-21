b := $(shell tput bold)
s := $(shell tput sgr0)
.DEFAULT_GOAL : help

help:
	@echo "\nLeggo Geral Compose"
	@echo "Este arquivo ajuda no levantamento dos containers da aplicação Painel localmente\n"
	@echo "COMO USAR:\n\t'make <comando>'\n"
	@echo "COMANDOS:"
	@echo "\t$(b)help$(s) \t\t\tMostra esta mensagem de ajuda"
	@echo "\t$(b)build-painel$(s)\tContrói todos os volumes e containers necessários" 
	@echo "\t$(b)build-no-cache-painel$(s)\tContrói todos os volumes e containers necessários sem cache"
	@echo "\t$(b)up-painel$(s)\tLevanta todos os containers do Painel"
	@echo "\t$(b)down-volumes-painel$(s)\tApaga todos os containers, incluindo volumes"
.PHONY: help

build-painel:
		python3 run painel build
.PHONY: build-painel

build-no-cache-painel:
		python3 run painel build --no-cache
.PHONY: build-no-cache-painel

up-painel:
		python3 run painel up
.PHONY: up-painel

down-volumes-painel:
		python3 run painel down --volumes
.PHONY: down-volumes-painel