#!/bin/bash
#esse arquivo inicia um container docker com uma imagem do snakemake e baixa o docker nela. Depois roda o setup_matrix e o snakemake (com todos os cores da máquina rodando em paralelo).
echo "Iniciando o Orquestrador Snakemake..."

MSYS_NO_PATHCONV=1 docker run -it --rm \
  -v "$(pwd)":"$(pwd)" \
  -w "$(pwd)" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  snakemake/snakemake:v7.32.4 bash -c "curl -sSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.9.tgz | tar -xzC /tmp/ && mv /tmp/docker/docker /usr/bin/ && ./setup_matrix.sh && snakemake --cores all -s workflow/Snakefile"
