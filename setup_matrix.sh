#!/bin/bash
set -e

echo "Criando pastas do projeto..."
mkdir -p data/raw/reference/Saccharomyces_cerevisiae data/raw/reference/Saccharomyces_paradoxus
mkdir -p data/raw/focal/Saccharomyces_mikatae data/raw/focal/Saccharomyces_eubayanus
mkdir -p data/raw/outgroup/Saccharomyces_uvarum data/raw/outgroup/Candida_glabrata

echo "Baixando genomas de referencia do NCBI..."
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz" -o ref_cerevisiae.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/002/079/055/GCA_002079055.1_ASM207905v1/GCA_002079055.1_ASM207905v1_genomic.fna.gz" -o ref_paradoxus.gz

echo "Baixando genomas focais e outgroups..."
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/166/975/GCA_000166975.1_ASM16697v1/GCA_000166975.1_ASM16697v1_genomic.fna.gz" -o S_mikatae.fa.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/001/298/625/GCA_001298625.1_SEUB3.0/GCA_001298625.1_SEUB3.0_genomic.fna.gz" -o S_eubayanus.fa.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/002/214/985/GCA_002214985.1_ASM221498v1/GCA_002214985.1_ASM221498v1_genomic.fna.gz" -o S_uvarum.fa.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/545/GCF_000002545.3_ASM254v2/GCF_000002545.3_ASM254v2_genomic.fna.gz" -o C_glabrata.fa.gz

echo "Descompactando nativamente com gunzip..."
gunzip -f ref_cerevisiae.gz ref_paradoxus.gz S_mikatae.fa.gz S_eubayanus.fa.gz S_uvarum.fa.gz C_glabrata.fa.gz

echo "Movendo referências para as pastas finais..."
mv ref_cerevisiae data/raw/reference/Saccharomyces_cerevisiae/Saccharomyces_cerevisiae.fasta
mv ref_paradoxus data/raw/reference/Saccharomyces_paradoxus/Saccharomyces_paradoxus.fasta

echo "Fragmentando genomas..."
cat << 'EOF' > simular_reads.py
import sys, random

fasta_in = sys.argv[1]
out_prefix = sys.argv[2]
num_reads = 25000
read_len = 100

print(f"Gerando reads para {out_prefix}...")

# Leitura simples de arquivo de texto extraído
with open(fasta_in, 'r') as f:
    seq = "".join([l.strip() for l in f if not l.startswith(">")])
    
seq_len = len(seq)

# Trava de segurança caso o download via curl tenha falhado
if seq_len < 1000:
    print(f"\nERRO FATAL: O genoma {fasta_in} está vazio ou corrompido.")
    print("O servidor do NCBI provávelmente derrubou a conexão.")
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

# Executa as simulações
python3 simular_reads.py S_mikatae.fa data/raw/focal/Saccharomyces_mikatae/Saccharomyces_mikatae
python3 simular_reads.py S_eubayanus.fa data/raw/focal/Saccharomyces_eubayanus/Saccharomyces_eubayanus
python3 simular_reads.py S_uvarum.fa data/raw/outgroup/Saccharomyces_uvarum/Saccharomyces_uvarum
python3 simular_reads.py C_glabrata.fa data/raw/outgroup/Candida_glabrata/Candida_glabrata

# Limpeza
rm *.fa simular_reads.py
echo "Setup biológico concluído com sucesso."
