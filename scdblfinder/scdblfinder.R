suppressMessages(library(hdf5r))
suppressMessages(library(scDblFinder))
suppressMessages(library(Matrix))
suppressMessages(library(SingleCellExperiment))
path <- commandArgs(trailingOnly = TRUE)[[1]]
infile <-  hdf5r::H5File$new(filename = "cellbender.h5", mode = "r")
counts <- infile[["matrix/data"]]
indices <- infile[["matrix/indices"]]
indptr <- infile[["matrix/indptr"]]
shp <- infile[["matrix/shape"]]
features <- infile[[paste0("matrix/", 'features/name')]][]
probs<-infile[["droplet_latents"]][["cell_probability"]]$read()
feat_barcodes <- infile[["droplet_latents"]][["barcode_indices_for_latents"]]$read()
feat_barcodes <- feat_barcodes + 1
barcodes <- infile[["matrix/barcodes"]]$read()
sparse.mat <- sparseMatrix(
    i = indices[] + 1,
    p = indptr[],
    x = as.numeric(x = counts[]),
    dims = shp[],
    repr = "T"
  )
barcodes <- infile[["matrix/barcodes"]]
features <- make.unique(names = features)
sparse.mat <- as(object = sparse.mat, Class = "dgCMatrix")

rownames(x = sparse.mat) <- features
colnames(x = sparse.mat) <- barcodes[]
sce <- SingleCellExperiment(list(counts=sparse.mat))
sce <- sce[, barcodes[feat_barcodes]]
names(probs) <- barcodes[feat_barcodes]
sce$cell_probability <- probs
sce <- sce[, sce$cell_probability>0.5]
infile$close_all()
sce <- sce[,colSums(counts(sce))>200]
sce <- scDblFinder(sce)
df = data.frame(doublet_score = sce$scDblFinder.score, doublet_ident = sce$scDblFinder.class, weighed_score = sce$scDblFinder.weighted, cxds_score=sce$scDblFinder.cxds_score, row.names = colnames(sce))
write.csv(df, "doublets.csv")