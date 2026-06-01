# Pega os argumentos passados pelo Snakemake
args <- commandArgs(trailingOnly = TRUE)
eigenvec_file <- args[1]
output_pdf <- args[2]

# Carrega a biblioteca (o contêiner já a possui)
library(ggplot2)

# Lê o arquivo do PLINK (sem cabeçalho por padrão)
# As colunas do PLINK são: FamilyID, IndividualID, PC1, PC2, PC3...
df <- read.table(eigenvec_file, header=FALSE)
colnames(df)[1:4] <- c("Pop", "Sample", "PC1", "PC2")

# Gera o gráfico PCA
p <- ggplot(df, aes(x=PC1, y=PC2, color=Pop)) +
  geom_point(size=4, alpha=0.8) +
  theme_minimal() +
  labs(title="Análise de Componentes Principais (PCA)",
       subtitle=basename(eigenvec_file),
       x="Componente Principal 1",
       y="Componente Principal 2") +
  theme(legend.position="right")

# Salva o PDF
ggsave(output_pdf, plot=p, width=8, height=6)
