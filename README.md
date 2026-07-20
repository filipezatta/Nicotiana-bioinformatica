# 🧬 Nicotiana Bioinformática Wiki

Bem-vindo à documentação oficial do pipeline analítico desenvolvido para o processamento de dados genômicos e populacionais de espécies do gênero *Nicotiana*, utilizando a abordagem de redução de complexidade (estilo DArTseq/RADseq).

---

## 📑 Sumário da Documentação
1. [Visão Geral da Arquitetura](#-visão-geral-da-arquitetura)
2. [Estrutura de Diretórios do Repositório](#-estrutura-de-diretórios-do-repositório)
3. [Componentes e Stack Tecnológica](#-componentes-e-stack-tecnológica)
4. [Fluxo de Execução (Pipeline Step-by-Step)](#-fluxo-de-execução-pipeline-step-by-step)
5. [Automação de Resultados e Integração Contínua](#-automação-de-resultados-e-integração-contínua)
6. [Guia de Operação e Comandos de Uso](#-guia-de-operação-e-comandos-de-uso)

---

## 🏗️ 1. Visão Geral da Arquitetura

O pipeline foi desenhado sob os princípios de **reprodutibilidade**, **portabilidade** e **isolamento de ambiente**. Utiliza o **Snakemake** como motor de gerenciamento de dependências direcionadas (DAG) e o **Docker** em conjunto com o ecossistema **Biocontainers** para executar cada ferramenta computacional em seu próprio contêiner isolado, eliminando conflitos de pacotes no sistema operacional hospedeiro.

---

## 📂 2. Estrutura de Diretórios do Repositório

A organização do projeto segue padrões rigorosos de bioinformática para garantir a separação entre dados brutos, códigos de controle e resultados gerados:

```text
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
