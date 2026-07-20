🧬 Nicotiana Bioinformática Wiki
Bem-vindo à documentação oficial do pipeline analítico desenvolvido para o processamento de dados genômicos e populacionais de espécies do gênero Nicotiana, utilizando a abordagem de redução de complexidade (estilo DArTseq/RADseq).

📑 Sumário da Documentação
Visão Geral da Arquitetura

Estrutura de Diretórios do Repositório

Componentes e Stack Tecnológica

Fluxo de Execução (Pipeline Step-by-Step)

Automação de Resultados e Integração Contínua

Guia de Operação e Comandos de Uso

🏗️ 1. Visão Geral da Arquitetura
O pipeline foi desenhado sob os princípios de reprodutibilidade, portabilidade e isolamento de ambiente. Utiliza o Snakemake como motor de gerenciamento de dependências direcionadas (DAG) e o Docker em conjunto com o ecossistema Biocontainers para executar cada ferramenta computacional em seu próprio contêiner isolado, eliminando conflitos de pacotes no sistema operacional hospedeiro.

📂 2. Estrutura de Diretórios do Repositório
A organização do projeto segue padrões rigorosos de bioinformática para garantir a separação entre dados brutos, códigos de controle e resultados gerados:

Plaintext
├── config/                  # Arquivos de parametrização global do pipeline
├── data/
│   └── raw/
│       ├── reads/           # Armazenamento obrigatório das bibliotecas .FASTQ.gz brutas da Illumina
│       └── illumina_adapter.fasta # Sequências de adaptadores sintéticos para filtragem
├── workflow/
│   └── Snakefile            # O núcleo do orquestrador (regras, dependências e scripts em Python)
├── enviar_resultados.sh     # Automação de sincronização e envio de relatórios ao GitHub
├── iniciar_pipeline.sh      # Script mestre de inicialização do orquestrador
└── setup_matrix.sh          # Script de estruturação física inicial do diretório
🛠️ 3. Componentes e Stack Tecnológica
O pipeline integra ferramentas validadas pela comunidade científica de bioinformática:

Snakemake: Orquestrador de fluxos de trabalho baseado em Python, responsável por calcular o caminho crítico de execução e paralelizar os processos.

Docker & Biocontainers: Camada de virtualização leve que abriga ferramentas isoladas (FastQC, ea-utils, BWA, Samtools, Freebayes, Bcftools, PLINK).

FastQC: Software de inspeção visual e estatística da qualidade das bases de sequenciamento bruto e limpo.

EA-Utils (fastq-mcf): Ferramenta de alta performance para o corte (trimming) de adaptadores sintéticos e filtragem por qualidade Phred.

BWA-MEM: Alinhador de sequências curtas de DNA altamente eficiente contra genomas de referência complexos.

SAMtools: Manipulação, ordenação, filtragem e indexação de arquivos de alinhamento binário (BAM/SAM).

Freebayes: Caller de variantes genéticas baseado em haplótipos e estatística Bayesiana, ideal para dados de populações vegetais e cortes enzimáticos.

Bcftools / PLINK / R (Tidyverse): Pós-processamento de variantes, filtragem de qualidade de genótipos, cálculo de distâncias genéticas e geração de componentes principais (PCA).

🔄 4. Fluxo de Execução (Pipeline Step-by-Step)
O processamento computacional divide-se em fases encadeadas de forma inteligente pelo Snakemake:

Fase 1: Controle de Qualidade Inicial (Raw QC)
FastQC Raw: Varre cada arquivo .FASTQ.gz bruto na pasta de entradas para gerar métricas de distribuição de qualidade por base, conteúdo GC e presença de adaptadores.

Extração de Estatísticas Brutas: Extrai o quantitativo total de sequências originais por indivíduo para auditoria laboratorial.

Fase 2: Limpeza e Filtragem (Trimming)
Fastq-mcf: Compara as sequências brutas contra o arquivo de adaptadores oficial (illumina_adapter.fasta), eliminando sequências curtas e bases com escore Phred inferior aos parâmetros definidos.

Fase 3: Controle de Qualidade Pós-Processamento
FastQC Trimmed & Stats: Reavalia as sequências limpas, computando a taxa de retenção real de reads e gerando a matriz consolidada de controle (QC_control_table.tsv).

🚀 5. Automação de Resultados e Integração Contínua
O pipeline conta com gatilhos de automação pós-execução (onsuccess):

Assim que a regra final de agregação e relatórios é concluída com sucesso, o script enviar_resultados.sh é acionado de forma autônoma.

Os arquivos essenciais de controle (tabelas de perdas de reads, logs do Snakemake e relatórios HTML de exemplo da amostra de referência) são compactados, copiados e sincronizados diretamente com o repositório remoto via git push.

💻 6. Guia de Operação e Comandos de Uso
Para executar o pipeline em um ambiente local com suporte a Docker ativado:

Insira os dados brutos:
Transfira os arquivos .FASTQ.gz da Illumina para o diretório correspondente:

Bash
data/raw/reads/
Valide o adaptador:
Certifique-se de que o arquivo de adaptadores está configurado corretamente em:

Bash
data/raw/illumina_adapter.fasta
Dispare o Orquestrador:
Execute o script mestre no terminal Linux ou Git Bash (assegurando que o Docker Desktop esteja rodando):

Bash
./iniciar_pipeline.sh
