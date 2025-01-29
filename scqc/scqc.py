import pandas as pd
from cellbender.remove_background.downstream import load_anndata_from_input_and_output
import sctk
adata = load_anndata_from_input_and_output("cellranger_adata.h5", "cellbender.h5")
df = pd.read_csv("doublets.csv", index_col=0, header=None)
adata = adata[adata.obs.index.isin(df.index)]
adata.obs["doublet_score"] = df[0]
adata.obs["doublet_ident"] = df[1]
adata.obs["weighed_score"] = df[2]
adata.obs["cxds_score"] = df[3]
sctk.calculate_qc(adata)
sctk.cellwise_qc(adata)
metrics = sctk.default_metric_params_df.loc[["n_counts",
    "n_genes",
    "percent_mito",
    "percent_ribo",
    "percent_hb"], :]
sctk.multi_resolution_cluster_qc(adata)
sctk.cellwise_qc(adata, metrics=metrics)
sctk.multi_resolution_cluster_qc(adata)


