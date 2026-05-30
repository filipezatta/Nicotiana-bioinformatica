#!/bin/bash
echo "Iniciando o Orquestrador Snakemake..."

MSYS_NO_PATHCONV=1 docker run -it --rm \
  -v "$(pwd):/workdir" \
  -w /workdir \
  -v /var/run/docker.sock:/var/run/docker.sock \
  snakemake/snakemake:v7.32.4 bash -c "curl -sSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.9.tgz | tar -xzC /tmp/ && mv /tmp/docker/docker /usr/bin/ && ./setup_matrix.sh && snakemake --cores all -s workflow/Snakefile"
