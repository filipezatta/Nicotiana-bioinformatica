# Nicotiana-bioinformatica

Pipeline reprodutível para o processamento de dados de genotipagem por representação reduzida (DArTseq) de espécies de *Nicotiana* sect. *Alatae*, desenvolvido para o Trabalho de Conclusão de Curso **"A escolha metodológica importa para a inferência de introgressão? Um teste em zonas híbridas de *Nicotiana*"** (Filipe Backes Zatta).

O objetivo do pipeline é processar um mesmo conjunto de leituras em **nove iterações independentes**, que combinam três **referências** e três **grupos externos**, mantendo constantes o genotipador (FreeBayes) e todos os demais parâmetros, para medir o efeito dessas escolhas sobre as inferências de estrutura populacional, hibridação e introgressão. A iteração 1 reproduz o pipeline de Couto *et al.* (2026, *Annals of Botany*, doi:[10.1093/aob/mcag083](https://doi.org/10.1093/aob/mcag083)) e serve de cenário de referência.

> **Estado atual:** a etapa 1 (controle de qualidade e filtragem das leituras) está implementada e funcional. As etapas seguintes estão em desenvolvimento; ver [Estado de implementação](#estado-de-implementação).

---

## Sumário

1. [Delineamento](#delineamento)
2. [Arquitetura](#arquitetura)
3. [Estado de implementação](#estado-de-implementação)
4. [Requisitos](#requisitos)
5. [Estrutura do repositório](#estrutura-do-repositório)
6. [Dados de entrada](#dados-de-entrada)
7. [Execução](#execução)
8. [Saídas](#saídas)
9. [Configuração](#configuração)
10. [Envio automático de resultados](#envio-automático-de-resultados)
11. [Versões dos programas](#versões-dos-programas)
12. [Referências](#referências)

---

## Delineamento

**Amostras:** 24 indivíduos-alvo em delineamento balanceado — *N. alata* Ala16, *N. forgetiana* Forg05, AP01-A (ancestralidade assimétrica) e AP01-B (mistura ~50/50), com 6 indivíduos cada — mais os indivíduos do grupo externo de cada iteração.

| Iteração | Referência | Genotipador | Grupo externo |
|---|---|---|---|
| 1 (cenário de referência) | *N. sylvestris* | FreeBayes | *N. bonariensis* |
| 2 | *N. sylvestris* | FreeBayes | *N. longiflora* |
| 3 | *N. sylvestris* | FreeBayes | *N. glauca* |
| 4 | *de novo* | FreeBayes | *N. bonariensis* |
| 5 | *de novo* | FreeBayes | *N. longiflora* |
| 6 | *de novo* | FreeBayes | *N. glauca* |
| 7 | *Petunia axillaris* | FreeBayes | *N. bonariensis* |
| 8 | *Petunia axillaris* | FreeBayes | *N. longiflora* |
| 9 | *Petunia axillaris* | FreeBayes | *N. glauca* |

- **Referências:** *N. sylvestris* (Sierro *et al.*, 2024; RefSeq GCF_000393655.2), *Petunia axillaris* (GenBank) e uma pseudorreferência *de novo* construída a partir das próprias leituras de cada iteração (abordagem dDocent: agrupamento com CD-HIT e mapeamento com BWA-MEM), o que mantém o FreeBayes como genotipador também nesse caso.
- **Grupos externos:** *N. bonariensis* e *N. longiflora* (sect. *Alatae*) e *N. glauca* (sect. *Noctiflorae*). O grupo externo entra na chamada conjunta de variantes, portanto afeta a iteração inteira, e não apenas os testes de introgressão.
- **Paralelismo:** cada iteração é um ramo independente do grafo do Snakemake. Apenas as leituras pré-processadas são compartilhadas; mapeamento, chamada, filtragem e análises são executados separadamente, com o mesmo arquivo de configuração.

```mermaid
flowchart TD
    A[Leituras DArTseq brutas<br/>FASTQ single-end] --> B[QC e filtragem<br/>FastQC · fastq-stats · fastq-mcf]
    B --> C[9 iterações em paralelo<br/>3 referências × 3 grupos externos]
    subgraph P[Pipeline idêntico em cada iteração]
      D[Obtenção dos locos<br/>BWA-MEM ou pseudorreferência de novo] --> E[Chamada conjunta<br/>FreeBayes · alvo + grupo externo]
      E --> F[Filtragem<br/>VCFtools · PLINK · pcadapt]
      F --> G[Estrutura populacional<br/>PCA · STRUCTURE · ADMIXTURE · NeighborNet · Arlequin]
      G --> H[Híbridos e introgressão<br/>snapclust · NewHybrids · D · fd · HyDe · SNaQ]
    end
    C --> D
    H --> I[Comparação entre iterações<br/>e com o cenário de referência]
```

## Arquitetura

- **Orquestração:** [Snakemake](https://snakemake.readthedocs.io) v7.32.4. O fluxo é descrito como um grafo de dependências entre arquivos (DAG); amostras e iterações são processadas de forma independente e em paralelo.
- **Isolamento de ambiente:** cada regra executa sua ferramenta em um contêiner Docker com versão fixa (imagens BioContainers e StaPH-B). Não é necessário instalar as ferramentas de bioinformática na máquina hospedeira.
- **Execução do orquestrador:** o próprio Snakemake roda em um contêiner (`snakemake/snakemake:v7.32.4`) com acesso ao socket Docker do hospedeiro (padrão *Docker-outside-of-Docker*), de modo que o pipeline pode ser executado em qualquer máquina com Docker, inclusive Windows (Git Bash) e servidores Linux.

## Estado de implementação

| Etapa | Ferramentas | Estado |
|---|---|---|
| 1. QC das leituras brutas | FastQC, fastq-stats | Implementada |
| 2. Remoção de adaptadores e filtragem por qualidade (Q30, ≥ 50 pb) | fastq-mcf | Implementada |
| 3. QC das leituras filtradas e tabela de retenção | FastQC, fastq-stats, Python | Implementada |
| 4. Download e indexação das referências; pseudorreferência *de novo* | NCBI FTP, BWA, SAMtools, CD-HIT | Planejada (rascunho em `setup_matrix.sh`) |
| 5. Mapeamento, ordenação e métricas (por iteração) | BWA-MEM, SAMtools | Planejada |
| 6. Chamada conjunta de variantes (por iteração) | FreeBayes | Planejada |
| 7. Filtragem de SNPs, LD e locos sob seleção | VCFtools, BCFtools, PLINK, pcadapt | Planejada |
| 8. Estrutura populacional | SNPRelate, STRUCTURE, ADMIXTURE, SplitsTree, Arlequin | Planejada (`workflow/scripts/plot_pca.R`) |
| 9. Híbridos e introgressão | adegenet (snapclust), NewHybrids, introgress, Dsuite, HyDe, PhyloNetworks (SNaQ), ADMIXTOOLS 2 | Planejada |
| 10. Comparação entre iterações | R (vegan, pophelper, lme4, emmeans) | Planejada |

## Requisitos

- Docker (Docker Desktop no Windows/macOS ou Docker Engine no Linux), com o daemon em execução.
- Bash. No Windows, Git Bash; a variável `MSYS_NO_PATHCONV=1`, já definida em `iniciar_pipeline.sh`, evita a conversão automática de caminhos.
- Acesso à internet na primeira execução, para baixar as imagens dos contêineres.
- Opcional: `git` com credenciais configuradas, se o envio automático de resultados for mantido.
- Opcional: Python com `streamlit` e `pyyaml`, para o configurador `app.py`.

## Estrutura do repositório

```text
.
├── config/
│   └── config.yaml              # Parâmetros globais (genotipadores, etapas de QC)
├── data/
│   └── raw/
│       ├── reads/               # Leituras brutas {amostra}.FASTQ.gz (não versionadas)
│       └── illumina_adapter.fasta
├── workflow/
│   ├── Snakefile                # Regras do pipeline
│   ├── scripts/
│   │   └── plot_pca.R           # Gráfico de PCA a partir de .eigenvec (PLINK)
│   └── dag.pdf                  # Grafo de dependências atual
├── iniciar_pipeline.sh          # Ponto de entrada: executa o Snakemake em contêiner
├── setup_matrix.sh              # Cria a árvore de diretórios de entrada
├── enviar_resultados.sh         # Copia relatórios e faz commit/push (ver abaixo)
├── app.py                       # Interface Streamlit para editar config.yaml
└── guia.txt                     # Comandos de referência rápida
```

Os diretórios `data/` e `results/` estão no `.gitignore`: dados brutos e resultados intermediários não são versionados.

## Dados de entrada

| Arquivo | Descrição |
|---|---|
| `data/raw/reads/{amostra}.FASTQ.gz` | Uma biblioteca *single-end* por indivíduo, como entregue pela DArT (já demultiplexada). O nome do arquivo, sem a extensão, é usado como identificador da amostra. A extensão deve ser exatamente `.FASTQ.gz` (maiúsculas). |
| `data/raw/illumina_adapter.fasta` | Sequência do adaptador Illumina usada pelo fastq-mcf (`AGATCGGAAGAG`). |

## Execução

### Execução completa em contêiner (recomendada)

```bash
git clone https://github.com/filipezatta/Nicotiana-bioinformatica.git
cd Nicotiana-bioinformatica

# 1. Copiar as leituras para data/raw/reads/
# 2. Iniciar o pipeline
bash iniciar_pipeline.sh
```

O script inicia o contêiner do Snakemake, instala o cliente Docker dentro dele, executa `setup_matrix.sh` e, em seguida, `snakemake --cores 30`. Ajuste o número de núcleos em `iniciar_pipeline.sh` de acordo com a máquina utilizada.

### Execução com Snakemake local

Com um ambiente conda/mamba que contenha o Snakemake (o Docker continua sendo necessário, pois as regras chamam `docker run`):

```bash
mamba activate smk
bash setup_matrix.sh
snakemake --cores 4 -s workflow/Snakefile
```

### Comandos úteis

```bash
# Simulação: lista as tarefas sem executá-las
snakemake -n -s workflow/Snakefile

# Grafo de dependências
snakemake --forceall --dag      -s workflow/Snakefile | dot -Tpdf > workflow/dag.pdf
snakemake --forceall --rulegraph -s workflow/Snakefile | dot -Tpdf > rulegraph.pdf
```

## Saídas

| Caminho | Conteúdo |
|---|---|
| `results/qc/fastqc/raw/{amostra}/` | Relatório FastQC das leituras brutas |
| `results/qc/stats/raw/{amostra}.RAW_stats.txt` | Número de leituras brutas |
| `results/trimmed/reads/{amostra}.trimmed.fastq.gz` | Leituras filtradas (Q30, ≥ 50 pb, sem adaptador) |
| `results/qc/fastqc/trimmed/{amostra}/` | Relatório FastQC das leituras filtradas |
| `results/qc/stats/trimmed/{amostra}.q30l50_stats.txt` | Número de leituras retidas |
| `results/qc/QC_control_table.tsv` | Tabela consolidada por amostra |

Colunas de `QC_control_table.tsv`:

| Coluna | Descrição |
|---|---|
| `targetid` | Identificador da amostra |
| `Raw_reads` | Leituras brutas |
| `Trimmed_Reads_Q30L50` | Leituras retidas após a filtragem |
| `initial_loss` | Leituras descartadas |
| `%_kept` | Proporção de leituras retidas |

## Configuração

`config/config.yaml` define os genotipadores a utilizar e as etapas de QC a executar:

```yaml
genotypers:
- freebayes
qc_steps:
  raw_reads_qc: true
  processed_reads_qc: true
  mapping_qc: true
  sorting_qc: true
  variant_call_qc: true
```

O arquivo é carregado pelo Snakefile, mas suas chaves ainda não controlam as regras; isso será feito à medida que as etapas 4–8 forem implementadas. O arquivo pode ser editado manualmente ou pela interface `streamlit run app.py`.

## Envio automático de resultados

Ao final de uma execução bem-sucedida, o bloco `onsuccess` do Snakefile chama `enviar_resultados.sh`, que:

1. copia `QC_control_table.tsv`, os relatórios FastQC de uma amostra de controle e o log mais recente do Snakemake para `relatorios_finais/`;
2. executa `git add`, `git commit` e `git push` desse diretório.

O envio é feito para o ramo em uso no momento da execução. Para desativá-lo, remova ou comente o bloco `onsuccess` no Snakefile.

## Versões dos programas

| Programa | Versão | Imagem |
|---|---|---|
| Snakemake | 7.32.4 | `snakemake/snakemake:v7.32.4` |
| FastQC | 0.12.1 | `staphb/fastqc:0.12.1` |
| ea-utils (fastq-mcf, fastq-stats) | 1.1.2-779 | `quay.io/biocontainers/ea-utils:1.1.2.779--h9dd4a16_0` |

As versões das ferramentas das etapas seguintes serão fixadas nesta tabela à medida que forem incorporadas.

## Referências

- Andrews S. 2010. FastQC: a quality control tool for high throughput sequence data.
- Aronesty E. 2013. Comparison of sequencing utility programs. *The Open Bioinformatics Journal* 7: 1–8.
- Couto MAMS, Soares LS, Rodrigues DM, *et al.* 2026. Genomic evidence of hybridization between two species in *Nicotiana* sect. *Alatae*. *Annals of Botany*. doi:10.1093/aob/mcag083
- Köster J, Rahmann S. 2012. Snakemake—a scalable bioinformatics workflow engine. *Bioinformatics* 28: 2520–2522.
- Mölder F, Jablonski KP, Letcher B, *et al.* 2021. Sustainable data analysis with Snakemake. *F1000Research* 10: 33.
- Sierro N, Auberson M, Dulize R, Ivanov NV. 2024. Chromosome-level genome assemblies of *Nicotiana tabacum*, *Nicotiana sylvestris*, and *Nicotiana tomentosiformis*. *Scientific Data* 11: 135.
