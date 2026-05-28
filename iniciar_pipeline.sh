#!/bin/bash
echo "Iniciando o Orquestrador Snakemake..."

MSYS_NO_PATHCONV=1 docker run -it --rm \
  -v "$(pwd):/workdir" \
  -w /workdir \
  -v /var/run/docker.sock:/var/run/docker.sock \
  snakemake/snakemake:v7.32.4 bash -c "./setup_matrix.sh && snakemake --cores all -s workflow/Snakefile"
