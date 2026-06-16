#!/bin/bash
set -e

#Esse arquivo faz várias coisas. Um resumo:
# cria os diretórios para os genomas que usaremos
# baixa os genomas do NCBI como .gz
# decompacta os genomas em .fasta
# PARA TESTE cria um arquivo python que picota os genomas em reads
# roda o simulador de reads
# deleta os arquivos .gz e .fa sobressalentes e o simulador de reads

if [ -f "data/raw/focal/Ala16/Ala16_ind1_1.fastq" ]; then
    echo "Os dados brutos já estão no disco. Pulando o download do NCBI e a simulação de reads..."
    exit 0
fi

# criando os diretórios
echo "Criando árvore de diretórios do Step 1 (Nicotiana)..."
mkdir -p data/raw/reference/N_sylvestris data/raw/reference/P_axillaris
mkdir -p data/raw/outgroup/N_tabacum data/raw/outgroup/N_tomentosiformis data/raw/outgroup/N_glauca
mkdir -p data/raw/focal/Ala16 data/raw/focal/Forg05 data/raw/focal/AP01-A data/raw/focal/AP01-B

#baixar -silent, -location (se a URL x dizer que mudou para a URL y, ele redireciona para a URL y), e -output para um zip
echo "Baixando genomas via NCBI FTP..."
# Referências (Links estáveis e testados)
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/393/655/GCF_000393655.1_Nsyl/GCF_000393655.1_Nsyl_genomic.fna.gz" -o ref_sylvestris.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/029/990/575/GCA_029990575.1_ASM2999057v1/GCA_029990575.1_ASM2999057v1_genomic.fna.gz" -o ref_axillaris.gz

# Outgroups (Substitutos temporários estáveis)
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/715/075/GCF_000715075.1_ASM71507v2/GCF_000715075.1_ASM71507v2_genomic.fna.gz" -o out_tabacum.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/390/325/GCF_000390325.3_ASM39032v3/GCF_000390325.3_ASM39032v3_genomic.fna.gz" -o out_tomentosiformis.gz
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/002/930/595/GCA_002930595.1_NicGla1.0/GCA_002930595.1_NicGla1.0_genomic.fna.gz" -o out_glauca.gz

# Focal Molde (N. benthamiana para simulação)
curl -sL "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/034/376/525/GCA_034376525.1_ASM3437652v1/GCA_034376525.1_ASM3437652v1_genomic.fna.gz" -o focal_benthamiana.gz

echo "Extraindo os genomas..."
python3 -c "
import gzip, shutil, sys
arquivos = [
    ('ref_sylvestris.gz', 'data/raw/reference/N_sylvestris/N_sylvestris.fasta'),
    ('ref_axillaris.gz', 'data/raw/reference/P_axillaris/P_axillaris.fasta'),
    ('out_tabacum.gz', 'out_tabacum.fa'),
    ('out_tomentosiformis.gz', 'out_tomentosiformis.fa'),
    ('out_glauca.gz', 'out_glauca.fa'),
    ('focal_benthamiana.gz', 'focal_molde.fa')
]
for gz_in, fa_out in arquivos:
    print(f'Extraindo {gz_in}...')
    try:
        with gzip.open(gz_in, 'rb') as f_in, open(fa_out, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)
    except Exception as e:
        print(f'Erro fatal em {gz_in}: {e}')
        sys.exit(1)
"

echo "Triturando genomas em reads FastQ (DArTseq Simulado)..."
cat << 'EOF' > simular_reads.py
import sys, random
fasta_in, out_prefix = sys.argv[1], sys.argv[2]
with open(fasta_in, 'r') as f:
    seq = "".join([l.strip() for l in f if not l.startswith(">")])
seq_len = len(seq)
q, trans = "I" * 100, str.maketrans("ATCGNatcgn", "TAGCNtagcn")
with open(f"{out_prefix}_1.fastq", "w") as f1, open(f"{out_prefix}_2.fastq", "w") as f2:
    for i in range(10000):
        idx = random.randint(0, seq_len - 500)
        r1, r2 = seq[idx:idx+100], seq[idx+200:idx+300].translate(trans)[::-1]
        if "N" not in r1 and "N" not in r2:
            f1.write(f"@MSEQ:1:FC:{i}/1\n{r1}\n+\n{q}\n")
            f2.write(f"@MSEQ:1:FC:{i}/2\n{r2}\n+\n{q}\n")
EOF

# Processa Outgroups
python3 simular_reads.py out_tabacum.fa data/raw/outgroup/N_tabacum/N_tabacum
python3 simular_reads.py out_tomentosiformis.fa data/raw/outgroup/N_tomentosiformis/N_tomentosiformis
python3 simular_reads.py out_glauca.fa data/raw/outgroup/N_glauca/N_glauca

# Processa os Focais baseados no molde da Benthamiana (24 indivíduos)
for pop in Ala16 Forg05 AP01-A AP01-B; do
    for ind in {1..6}; do
        python3 simular_reads.py focal_molde.fa data/raw/focal/$pop/${pop}_ind${ind}
    done
done

rm *.gz *.fa simular_reads.py
echo "Setup biológico das Nicotianas concluído."
