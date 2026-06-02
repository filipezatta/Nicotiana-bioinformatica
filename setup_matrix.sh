#!/bin/bash
set -e

echo "Criando pastas do projeto..."
mkdir -p data/raw/reference/Saccharomyces_cerevisiae data/raw/reference/Saccharomyces_paradoxus
mkdir -p data/raw/focal/Saccharomyces_mikatae data/raw/focal/Saccharomyces_eubayanus
mkdir -p data/raw/outgroup/Saccharomyces_uvarum data/raw/outgroup/Candida_glabrata

echo "Baixando genomas (.gz) do NCBI..."
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz" -o ref_cerevisiae.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/002/079/055/GCA_002079055.1_ASM207905v1/GCA_002079055.1_ASM207905v1_genomic.fna.gz" -o ref_paradoxus.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/166/975/GCA_000166975.1_ASM16697v1/GCA_000166975.1_ASM16697v1_genomic.fna.gz" -o S_mikatae.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/001/298/625/GCA_001298625.1_SEUB3.0/GCA_001298625.1_SEUB3.0_genomic.fna.gz" -o S_eubayanus.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/002/214/985/GCA_002214985.1_ASM221498v1/GCA_002214985.1_ASM221498v1_genomic.fna.gz" -o S_uvarum.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/545/GCF_000002545.3_ASM254v2/GCF_000002545.3_ASM254v2_genomic.fna.gz" -o C_glabrata.gz

echo "Descompactando arquivos usando Python (substituindo gunzip)..."
python3 -c "
import gzip, shutil, sys
arquivos = [
    ('ref_cerevisiae.gz', 'data/raw/reference/Saccharomyces_cerevisiae/Saccharomyces_cerevisiae.fasta'),
    ('ref_paradoxus.gz', 'data/raw/reference/Saccharomyces_paradoxus/Saccharomyces_paradoxus.fasta'),
    ('S_mikatae.gz', 'S_mikatae.fa'),
    ('S_eubayanus.gz', 'S_eubayanus.fa'),
    ('S_uvarum.gz', 'S_uvarum.fa'),
    ('C_glabrata.gz', 'C_glabrata.fa')
]
for gz_in, fa_out in arquivos:
    print(f'Extraindo {gz_in}...')
    try:
        with gzip.open(gz_in, 'rb') as f_in:
            with open(fa_out, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
    except Exception as e:
        print(f'Erro ao extrair {gz_in}: {e}')
        sys.exit(1)
"

echo "Fragmentando genomas (Gerando FastQs)..."
cat << 'EOF' > simular_reads.py
import sys, random

fasta_in = sys.argv[1]
out_prefix = sys.argv[2]
num_reads = 25000
read_len = 100

print(f"Gerando reads para {out_prefix}...")

with open(fasta_in, 'r') as f:
    seq = "".join([l.strip() for l in f if not l.startswith(">")])
    
seq_len = len(seq)

if seq_len < 1000:
    print(f"\nERRO FATAL: O genoma {fasta_in} está vazio.")
    sys.exit(1)

q = "I" * read_len
trans = str.maketrans("ATCGNatcgn", "TAGCNtagcn")

with open(f"{out_prefix}_1.fastq", "w") as f1, open(f"{out_prefix}_2.fastq", "w") as f2:
    for i in range(num_reads):
        idx = random.randint(0, seq_len - 500)
        r1 = seq[idx:idx+read_len]
        r2_raw = seq[idx+200:idx+200+read_len]
        r2 = r2_raw.translate(trans)[::-1]
        
        if "N" not in r1 and "N" not in r2 and len(r1) == read_len and len(r2) == read_len:
            f1.write(f"@MSEQ:1:FC:{i}/1\n{r1}\n+\n{q}\n")
            f2.write(f"@MSEQ:1:FC:{i}/2\n{r2}\n+\n{q}\n")
EOF

# Executa as simulações já usando os arquivos puros extraídos
python3 simular_reads.py S_mikatae.fa data/raw/focal/Saccharomyces_mikatae/Saccharomyces_mikatae
python3 simular_reads.py S_eubayanus.fa data/raw/focal/Saccharomyces_eubayanus/Saccharomyces_eubayanus
python3 simular_reads.py S_uvarum.fa data/raw/outgroup/Saccharomyces_uvarum/Saccharomyces_uvarum
python3 simular_reads.py C_glabrata.fa data/raw/outgroup/Candida_glabrata/Candida_glabrata

# Limpeza pesada
rm *.gz *.fa simular_reads.py
echo "Setup biológico concluído com sucesso."
