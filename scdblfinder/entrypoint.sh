#!/bin/bash
CELLBENDER_URL=$1
if [[ $1 == "none" ]]; then
    aws s3 cp $MANIFEST manifest.txt
    CELLBENDER_URL=$(awk "NR == ((${AWS_BATCH_JOB_ARRAY_INDEX} + 1))" manifest.txt)
fi

result=$(aws s3api list-objects-v2 --bucket ${BUCKET} --prefix "${CELLBENDER_URL#"s3://${BUCKET}/"}cellbender_retrain" --query 'Contents[]')
if [[ $result == "null" ]]; then
    aws s3 cp "${CELLBENDER_URL}cellbender/cellbender.h5" .
else
    aws s3 cp "${CELLBENDER_URL}cellbender_retrain/cellbender.h5" .
fi
Rscript scdblfinder.R "cellbender.h5"
aws s3 cp doublets.csv $CELLBENDER_URL