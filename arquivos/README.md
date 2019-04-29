# Módulo de emendas - Geração de distâncias

A geração das distâncias das emendas para o texto inicial de uma proposição segue os seguintes passos:

## 1. Baixar arquivos, convertê-los e processá-los
### 1.1. Gerar a tabela com os links para os arquivos dos textos e emendas
Esta tabela é gerada utilizando o script `fetcher.R` implementado e descrito [neste repositório](https://github.com/analytics-ufcg/versoes-de-proposicoes). o resultado do script é o csv `versoes_leggo.csv`

### 1.2. Download dos arquivos em pdf
Para baixar os arquivos dos textos e emendas das proposições, utilize o script `download_csv_prop.py` disponível [neste repositório](https://github.com/analytics-ufcg/leggo-content/tree/master/util/data). O resultado pode ser encontrado em `/pdf/`.

### 1.3. Conversão para txt
O próximo passo é converter os arquivos baixados para txt. Antes disso, deve-se instalar o [Colibre](https://calibre-ebook.com/). Depois, seguir as intruções de execução do script `calibre_convert.sh` que podem ser encontradas [aqui](https://github.com/analytics-ufcg/leggo-content/tree/master/util/data). O resultado pode ser encontrado em `/txt/`.

### 1.4. Separar justificação do texto contendo a modificação das emendas
Para separar a justificação do texto, quando possível, deve-se executar o script `SepararJustificacoes.py` disponível neste [link](https://github.com/analytics-ufcg/leggo-content/blob/master/util/tools/SepararJustificacoes.py).  O resultado pode ser encontrado em `/txt/justificacoes/`.

## 2. Cálculo das distâncias
Uma vez que os arquivos foram baixados, convertidos e processados, o próximo passo é executar o script `inter_emd_int.py`, que pode ser encontrado [aqui](https://github.com/analytics-ufcg/leggo-content/tree/master/coherence/inter_emd_int). 

