install.packages(c("BiocManager", "devtools", "hdf5r"), dependencies=TRUE, repos='http://cran.rstudio.com/')
BiocManager::install("scDblFinder", update=F, ask=F)