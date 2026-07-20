#!/bin/bash

echo "Coletando relatórios e logs..."
mkdir -p relatorios_finais

# 1. Copia a tabela de trimagem
cp results/qc/QC_control_table.tsv relatorios_finais/ 2>/dev/null || echo "Aviso: Tabela de QC não encontrada."

# 2. Copia os relatórios HTML da read 2712275 (Raw e Trimmed) renomeando para evitar conflitos
cp results/qc/fastqc/raw/2712275/*fastqc.html relatorios_finais/2712275_RAW_fastqc.html 2>/dev/null || echo "Aviso: FastQC RAW do 2712275 não encontrado."
cp results/qc/fastqc/trimmed/2712275/*fastqc.html relatorios_finais/2712275_TRIMMED_fastqc.html 2>/dev/null || echo "Aviso: FastQC Trimmed do 2712275 não encontrado."

# 3. Pesca o log mais recente gerado pelo Snakemake
LOG_FILE=$(ls -t .snakemake/log/*.log 2>/dev/null | head -n 1)
if [ -n "$LOG_FILE" ]; then
    cp "$LOG_FILE" relatorios_finais/snakemake_ultima_execucao.log
    echo "Log do Snakemake capturado."
else
    echo "Aviso: Nenhum log do Snakemake encontrado."
fi

echo "Sincronizando com o GitHub..."
git add relatorios_finais/
git commit -m "docs: adiciona tabela QC, HTMLs do 2712275 e log do Snakemake"
git push

echo "Sucesso! Os relatórios estão no seu repositório."
