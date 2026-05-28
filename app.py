import streamlit as st
import yaml
import os

# Configuração da página
st.set_page_config(page_title="Snakemake Configurator", layout="centered")

st.title("🧬 Nicotiana Pipeline Configurator")
st.markdown("Painel de controle para o pipeline de genotipagem conjunta.")

# --- SEÇÃO 1: GENOTIPADORES ---
st.header("1. Genotipadores")
genotypers = st.multiselect(
    "Selecione as ferramentas de Variant Calling:",
    options=["freebayes", "gatk"],
    default=["freebayes", "gatk"]
)

# --- SEÇÃO 2: CONTROLE DE QUALIDADE ---
st.header("2. Controle de Qualidade (QC)")
st.markdown("Ative ou desative os passos de verificação de qualidade:")

col1, col2 = st.columns(2)
with col1:
    raw_qc = st.toggle("QC de Reads Brutas", value=False)
    processed_qc = st.toggle("QC de Reads Processadas", value=False)
    mapping_qc = st.toggle("QC de Mapeamento", value=True)
with col2:
    sorting_qc = st.toggle("QC de Ordenação", value=False)
    variant_qc = st.toggle("QC de Variantes", value=False)

# --- CONSTRUÇÃO DO DICIONÁRIO ---
config_dict = {
    "genotypers": genotypers,
    "qc_steps": {
        "raw_reads_qc": raw_qc,
        "processed_reads_qc": processed_qc,
        "mapping_qc": mapping_qc,
        "sorting_qc": sorting_qc,
        "variant_call_qc": variant_qc
    }
}

# --- SEÇÃO 3: PREVIEW E EXPORTAÇÃO ---
st.header("3. Preview e Exportação")
yaml_string = yaml.dump(config_dict, default_flow_style=False, sort_keys=False)

st.code(yaml_string, language="yaml")

if st.button("💾 Salvar em config/config.yaml", use_container_width=True):
    # Garante que a pasta config existe
    os.makedirs("config", exist_ok=True)
    
    # Salva o arquivo sobrescrevendo o anterior
    with open("config/config.yaml", "w") as f:
        f.write(yaml_string)
    
    st.success("✅ Arquivo config.yaml atualizado com sucesso! Pronto para rodar o Snakemake.")
