#!/bin/bash
set -e

echo "Criando árvore de diretórios base..."
mkdir -p data/raw/reads  # PASTA PARA AS SUAS READS DA ILLUMINA

echo "Gerando banco de adaptadores universais Illumina..."
cat << 'EOF' > data/raw/illumina_adapter.fasta
>Illumina_Universal_Adapter
AGATCGGAAGAG
EOF

# ==========================================
# SEÇÃO SUSPENSA PARA O STEP 1 (APENAS QC)
# ==========================================
# mkdir -p data/raw/reference/N_sylvestris data/raw/reference/P_axillaris
# mkdir -p data/raw/outgroup/N_tabacum data/raw/outgroup/N_tomentosiformis data/raw/outgroup/N_glauca
# 
# echo "Baixando genomas via NCBI FTP..."
# curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/393/655/GCF_000393655.1_Nsyl/GCF_000393655.1_Nsyl_genomic.fna.gz" -o ref_sylvestris.gz
# curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/029/990/575/GCA_029990575.1_ASM2999057v1/GCA_029990575.1_ASM2999057v1_genomic.fna.gz" -o ref_axillaris.gz
# ... (demais downloads e scripts Python) ...
# ==========================================

echo "Setup de QC concluído. Cole os arquivos .FASTQ.gz na pasta 'data/raw/reads/' e inicie o pipeline."
