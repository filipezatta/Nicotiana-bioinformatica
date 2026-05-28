# Nicotiana-bioinformatica
por enquanto pipeline de teste nos resultados para diferentes genotypers,outgroups,references.


Este repositório documenta a infraestrutura como código desenvolvida para o processamento de genomas híbridos do gênero Nicotiana. O sistema automatiza o alinhamento de sequências curtas (reads) e a chamada de variantes (Variant Calling), processando iterativamente múltiplas referências contra múltiplos grupos externos (outgroups).
1. Arquitetura de Diretórios e Regras de Inferência

O pipeline utiliza a função glob_wildcards do Snakemake para inferir dinamicamente a matriz de processamento com base na estrutura de pastas.

Aviso crítico: O sistema depende estritamente da nomenclatura abaixo. A quebra desse padrão (ex: arquivos fora das pastas designadas ou erros de digitação nos nomes) impedirá o Snakemake de montar o Grafo Acíclico Direcionado (DAG) e o pipeline falhará.
Plaintext

projeto_hibridos/
├── config/
│   └── config.yaml          # Define parâmetros booleanos e listas (Genotipadores, QC)
├── data/
│   └── raw/
│       ├── input/           # Subpastas nomeadas por amostra contendo reads paired-end (.fastq)
│       └── reference/       # Subpastas nomeadas por espécie contendo o genoma (.fasta)
├── results/
│   ├── mapping/             # Arquivos alinhados (.bam) e seus índices (.bai)
│   ├── vcf/                 # Arquivos de variantes gerados
│   └── qc/                  # Arquivos de estatísticas e relatórios html
└── workflow/
    └── Snakefile            # O código fonte do orquestrador

2. Ferramentas e Contêineres Utilizados

Para garantir reprodutibilidade, nenhuma ferramenta genômica é instalada nativamente no sistema operacional hospedeiro. O pipeline invoca contêineres Docker isolados para cada processo.

    Snakemake: O orquestrador principal. Ele analisa a regra final (rule all) e trabalha de trás para frente, determinando quais etapas precisam ser executadas com base nos arquivos presentes ou ausentes no disco. Ele paralela trabalhos automaticamente e evita o reprocessamento de arquivos que não foram alterados.

    BWA-MEM (v0.7.17): Algoritmo de alinhamento projetado para reads da Illumina. Utiliza a Transformada de Burrows-Wheeler para encontrar rapidamente a posição de origem de cada fragmento no genoma de referência. É resiliente a mismatches e pequenos indels (inserções/deleções).

    Samtools (v1.17): Utilitário essencial para interagir com dados de sequenciamento de alto rendimento. Neste pipeline, é responsável por traduzir dados brutos (SAM) para formato binário comprimido (BAM), ordenar as reads por coordenada cromossômica e construir índices de acesso rápido (.bai, .fai).

    GATK HaplotypeCaller (v4.4.0.0): Algoritmo padrão-ouro do Broad Institute para identificação de SNPs e Indels. Em vez de avaliar nucleotídeo por nucleotídeo, ele identifica regiões ativas com mutações e realiza uma montagem de novo (de-novo assembly) local dos haplótipos. É altamente rigoroso quanto à formatação do arquivo de entrada (exige Read Groups e arquivos de dicionário).

    Freebayes (v1.3.6): Genotipador baseado em haplótipos probabilísticos. Diferente do GATK, ele consegue detectar polimorfismos de nucleotídeo múltiplo (MNPs) e eventos complexos avaliando o alinhamento de forma direta, ignorando suposições de ploidia engessadas.

    MultiQC: Analisador de logs. Escaneia o diretório de saídas e compila as estatísticas brutas do Samtools (e outras ferramentas) em um relatório visualização único.

3. Etapas de Processamento (Snakemake Workflow)

A execução do arquivo Snakefile segue uma ordem cronológica estrita de dependências:
Etapa 1: Leitura de Configurações e Inferência de Alvos

O Snakemake lê o arquivo config.yaml para determinar quais genotipadores estão ativos. Em seguida, mapeia as pastas em data/raw/reference/ e data/raw/input/ para construir a matriz (ex: Referência A cruzada com Outgroup X, Y e Z). A rule all dita que o objetivo final é a presença de todos os arquivos .vcf resultantes dessa matriz cruzada.
Etapa 2: Download Dinâmico (Condicional)

Se o pipeline detectar que o arquivo FASTA da referência está ausente, a regra baixar_referencias é acionada. O genoma é baixado via FTP oficial do NCBI e descompactado no diretório adequado.
Etapa 3: Preparação do Genoma (Indexação)

Antes que qualquer mapeamento ou chamada de variantes ocorra, a referência deve ser indexada em três formatos distintos:

    rule indexar_bwa: Gera os índices estruturais (.bwt, .pac, .ann, etc.) necessários para que o algoritmo de alinhamento funcione.

    rule indexar_samtools_fai: Cria um índice .fai do arquivo FASTA, permitindo que ferramentas leiam cromossomos específicos sem carregar o genoma inteiro na RAM.

    rule criar_dicionario_gatk: Cria um arquivo .dict, que é uma exigência estrita e exclusiva do GATK contendo o tamanho e nome dos contigs.

Etapa 4: Mapeamento e Ordenação Simultânea

A rule mapeamento_bwa é o núcleo de processamento intensivo.

    O BWA-MEM alinha as reads Paired-End contra o genoma.

    Durante a execução, o parâmetro -R injeta a etiqueta de identificação de amostra (Read Group @RG) no cabeçalho.

    O fluxo de dados (pipe |) envia a saída padrão diretamente para o samtools sort. O arquivo .sam intermediário nunca é escrito no disco, economizando dezenas de Gigabytes. O arquivo final .sorted.bam é salvo na pasta results/mapping/.

Etapa 5: Indexação do Alinhamento

A rule indexar_bam executa samtools index sobre os arquivos .sorted.bam. Isso gera um arquivo .bai. Sem este arquivo, os genotipadores não conseguem particionar a busca de mutações, resultando em erro.
Etapa 6: Chamada de Variantes (Genotipagem)

Duas regras processam os mesmos dados em paralelo, gerando abordagens estatísticas diferentes:

    rule freebayes: Lê a referência e o arquivo BAM, extraindo diretamente as variantes para o arquivo .vcf.

    rule gatk_haplotype_caller: Valida a presença do .fai e do .dict, lê o BAM contendo os Read Groups criados na Etapa 4 e gera a sua versão independente do arquivo .vcf.

4. Execução do Sistema

Para acionar a matriz completa de processamento, utilize o comando abaixo. A tag --cores define quantos threads do sistema o Snakemake está autorizado a alocar para paralelizamento de regras.
Bash

snakemake --cores all -s workflow/Snakefile
