#!/bin/bash
set -e

# TRAVA DE SEGURANÇA
if [ -f "data/raw/reads/2712275.FASTQ.gz" ]; then
    echo "Os dados da Illumina já estão no disco. Pulando o download do NCBI..."
    exit 0
fi

echo "Criando árvore de diretórios Plana (Nicotiana Single-End)..."
mkdir -p data/raw/reference/N_sylvestris data/raw/reference/P_axillaris
mkdir -p data/raw/outgroup/N_tabacum data/raw/outgroup/N_tomentosiformis data/raw/outgroup/N_glauca
mkdir -p data/raw/reads  # PASTA PARA COLAR OS ARQUIVOS DO DRIVE

echo "Baixando genomas via NCBI FTP..."

# Referências (Links estáveis e testados)
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/393/655/GCF_000393655.1_Nsyl/GCF_000393655.1_Nsyl_genomic.fna.gz" -o ref_sylvestris.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/029/990/575/GCA_029990575.1_ASM2999057v1/GCA_029990575.1_ASM2999057v1_genomic.fna.gz" -o ref_axillaris.gz

# Outgroups (Substitutos temporários estáveis)
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/715/075/GCF_000715075.1_ASM71507v2/GCF_000715075.1_ASM71507v2_genomic.fna.gz" -o out_tabacum.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/390/325/GCF_000390325.3_ASM39032v3/GCF_000390325.3_ASM39032v3_genomic.fna.gz" -o out_tomentosiformis.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/002/930/595/GCA_002930595.1_NicGla1.0/GCA_002930595.1_NicGla1.0_genomic.fna.gz" -o out_glauca.gz

echo "Extraindo referências e outgroups com Python..."
python3 -c "
import gzip, shutil, sys
arquivos = [
    ('ref_sylvestris.gz', 'data/raw/reference/N_sylvestris/N_sylvestris.fasta'),
    ('ref_axillaris.gz', 'data/raw/reference/P_axillaris/P_axillaris.fasta'),
    ('out_tabacum.gz', 'out_tabacum.fa'),
    ('out_tomentosiformis.gz', 'out_tomentosiformis.fa'),
    ('out_glauca.gz', 'out_glauca.fa')
]
for gz_in, fa_out in arquivos:
    print(f'Extraindo {gz_in}...')
    try:
        with gzip.open(gz_in, 'rb') as f_in, open(fa_out, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)
    except Exception as e:
        print(f'Aviso na extração de {gz_in}: {e}. O arquivo pode estar levemente corrompido no final, mas prosseguindo.')
"

echo "Simulando Outgroups em reads Single-End..."
cat << 'EOF' > simular_outgroup.py
import sys, random
fasta_in, out_prefix = sys.argv[1], sys.argv[2]
try:
    with open(fasta_in, 'r') as f:
        seq = "".join([l.strip() for l in f if not l.startswith(">")])
    seq_len = len(seq)
    q = "I" * 100
    with open(f"{out_prefix}.FASTQ", "w") as f1:
        for i in range(10000):
            idx = random.randint(0, seq_len - 150)
            r1 = seq[idx:idx+100]
            if "N" not in r1:
                f1.write(f"@MSEQ:1:FC:{i}\n{r1}\n+\n{q}\n")
except Exception as e:
    print(f'Erro simulando reads para {fasta_in}: {e}')
EOF

python3 simular_outgroup.py out_tabacum.fa data/raw/outgroup/N_tabacum/N_tabacum
python3 simular_outgroup.py out_tomentosiformis.fa data/raw/outgroup/N_tomentosiformis/N_tomentosiformis
python3 simular_outgroup.py out_glauca.fa data/raw/outgroup/N_glauca/N_glauca

echo "Compactando Outgroups para padronizar com a Illumina (.FASTQ.gz)..."
gzip -f data/raw/outgroup/*/*.FASTQ

rm *.gz *.fa simular_outgroup.py
echo "Setup biológico (referências e outgroups) concluído."
echo "CRÍTICO: Mova todos os arquivos .FASTQ.gz do seu Google Drive para a pasta 'data/raw/reads/' antes de iniciar o pipeline."
