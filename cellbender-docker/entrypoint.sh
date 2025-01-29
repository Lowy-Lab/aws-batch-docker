#!/bin/bash --login
lr=$1
epochs=$2
if [[ $3 == "none" ]]; then
	aws s3 cp $MANIFEST manifest.txt
	CELLBENDER_URL=$(awk "NR == ((${AWS_BATCH_JOB_ARRAY_INDEX} + 1))" manifest.txt)
else
	CELLBENDER_URL=$3
fi
./check_shutdown.sh $CELLBENDER_URL &
aws s3 cp $CELLBENDER_URL . --recursive --exclude "*" --include "ckpt.tar.gz" --include "cellranger_adata.h5ad" --include "cellbender" --include "cellbender_retrain"
mv cellranger_adata.h5ad cellranger_adata.h5
conda activate cellbender
set -euo pipefail
if [ ! -f cellbender/cellbender.h5ad ]; then
	mkdir -p cellbender
	cellbender remove-background --input "cellranger_adata.h5"  --cuda --output cellbender/cellbender.h5ad --learning-rate $lr --epochs $2
	mv ckpt.tar.gz cellbender
	aws s3 cp cellbender "${CELLBENDER_URL}cellbender" --recursive
fi
set +euo pipefail
convergence=$(awk -F "," 'NR==16 {print $NF}' cellbender/cellbender_metrics.csv)
if grep -q "<p>This is.*unusual" cellbender/cellbender_report.html || (( $(echo "$convergence > 1" | bc -l) )); then
	set -euo pipefail
	mkdir -p cellbender_retrain
	if [ -f cellbender_retrain/ckpt.tar.gz ]; then
		exit 0
	fi
	cellbender remove-background --input "cellranger_adata.h5" --cuda --output cellbender_retrain/cellbender.h5ad --learning-rate $(echo "${lr} / 2" | bc -l) --epochs $2
	mv ckpt.tar.gz cellbender_retrain
	aws s3 cp cellbender_retrain "${CELLBENDER_URL}cellbender_retrain" --recursive
fi
