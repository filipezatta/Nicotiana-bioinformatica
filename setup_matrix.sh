#!/bin/bash
set -e

echo "Criando estrutura do projeto Saccharomyces (48 Iterações)..."
mkdir -p data/raw/reference/Saccharomyces_cerevisiae data/raw/reference/Saccharomyces_paradoxus
mkdir -p data/raw/focal/Saccharomyces_boulardii data/raw/focal/Saccharomyces_mikatae data/raw/focal/Saccharomyces_kudriavzevii data/raw/focal/Saccharomyces_eubayanus
mkdir -p data/raw/outgroup/Saccharomyces_uvarum data/raw/outgroup/Kluyveromyces_lactis data/raw/outgroup/Candida_glabrata

# Baixa as referências
wget -qO data/raw/reference/Saccharomyces_cerevisiae/Saccharomyces_cerevisiae.fasta.gz https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz
gunzip -f data/raw/reference/Saccharomyces_cerevisiae/Saccharomyces_cerevisiae.fasta.gz

wget -qO data/raw/reference/Saccharomyces_paradoxus/Saccharomyces_paradoxus.fasta.gz https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/002/079/055/GCA_002079055.1_ASM207905v1/GCA_002079055.1_ASM207905v1_genomic.fna.gz
gunzip -f data/raw/reference/Saccharomyces_paradoxus/Saccharomyces_paradoxus.fasta.gz

echo "Gerando sequências simuladas para Focais e Outgroups..."
# Função rápida para gerar FASTQs simulados e evitar dependências de download do SRA
generate_mock_fastq() {
    local name=$1
    local dir=$2
    # Cria ~50 reads simples (100bp)
    for i in {1..50}; do
        echo -e "@Read${i}/1\nATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" >> ${dir}/${name}_1.fastq
        echo -e "@Read${i}/2\nCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGAT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" >> ${dir}/${name}_2.fastq
    done
}

# Focais
generate_mock_fastq "Saccharomyces_boulardii" "data/raw/focal/Saccharomyces_boulardii"
generate_mock_fastq "Saccharomyces_mikatae" "data/raw/focal/Saccharomyces_mikatae"
generate_mock_fastq "Saccharomyces_kudriavzevii" "data/raw/focal/Saccharomyces_kudriavzevii"
generate_mock_fastq "Saccharomyces_eubayanus" "data/raw/focal/Saccharomyces_eubayanus"

# Outgroups
generate_mock_fastq "Saccharomyces_uvarum" "data/raw/outgroup/Saccharomyces_uvarum"
generate_mock_fastq "Kluyveromyces_lactis" "data/raw/outgroup/Kluyveromyces_lactis"
generate_mock_fastq "Candida_glabrata" "data/raw/outgroup/Candida_glabrata"

echo "Setup concluído."
