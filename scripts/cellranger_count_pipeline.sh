#!/bin/bash

set -euo pipefail

########################################################
# 1. INPUTS
########################################################

FASTQ_DIR=$1
OUT_DIR=$2
DOWN_SAMPLE_VALUE=$3
GENOME_REF=$4

mkdir -p "$OUT_DIR"

echo "Starting single-cell RNA-seq preprocessing pipeline"

########################################################
# 2. FIND MINIMUM READ DEPTH (DOWNSAMPLING TARGET)
########################################################

echo "Calculating minimum read depth..."

MIN_READS=$(ls "$FASTQ_DIR"/*.fastq.gz | \
parallel -j 20 'zcat {} | wc -l | awk "{print \$1/4}"' | \
sort -n | head -1)

echo "Minimum read count = $MIN_READS"

########################################################
# 3. CREATE DOWNSAMPLING DIRECTORY
########################################################

DS_DIR="$FASTQ_DIR/ds"
mkdir -p "$DS_DIR"

echo "Downsampling FASTQ files..."

########################################################
# 4. DOWNSAMPLE FASTQ FILES
########################################################

ls "$FASTQ_DIR"/*.fastq.gz | parallel -j 4 \
"seqtk sample -s100 {} $DOWN_SAMPLE_VALUE > $DS_DIR/{/}.fastq"

########################################################
# 5. VERIFY DOWNSAMPLING
########################################################

echo "Verifying downsampled reads..."

for f in "$DS_DIR"/*.fastq
do
    echo $(cat "$f" | wc -l)/4 | bc
done

########################################################
# 6. COMPRESS FILES
########################################################

echo "Compressing FASTQ files..."

ls "$DS_DIR"/*.fastq | parallel -j 4 "gzip {}"

########################################################
# 7. FIX FILENAMES
########################################################

echo "Fixing file extensions..."

for f in "$DS_DIR"/*.fastq.gz.fastq.gz
do
    mv -- "$f" "${f%.fastq.gz.fastq.gz}.fastq.gz"
done

########################################################
# 8. ORGANIZE BY CONDITION
########################################################

echo "Organizing samples by condition..."

mkdir -p "$DS_DIR"/{mock,pos,test}

# NOTE: adapt naming pattern if needed
mv "$DS_DIR"/*mock* "$DS_DIR/mock/" || true
mv "$DS_DIR"/*POS* "$DS_DIR/pos/" || true
mv "$DS_DIR"/*test* "$DS_DIR/test/" || true
# Note: For fastq folder creation, use the following as example: Name_SC__11_061726, disregard everything afterwards. (Name_SC__11_061726_S3_L001_R1_001.fastq.gz)

########################################################
# 9. RUN CELL RANGER PER SAMPLE
########################################################

echo "Running Cell Ranger..."

for sample_dir in "$DS_DIR"/*
do
    SAMPLE_NAME=$(basename "$sample_dir")

    echo "Processing $SAMPLE_NAME"

    cellranger count \
        --id="$SAMPLE_NAME" \
        --transcriptome="$GENOME_REF" \
        --fastqs="$sample_dir" \
        --sample="$SAMPLE_NAME" \
        --create-bam true \
        --localcores=16 \
        --localmem=64

done

########################################################
# 10. AGGREGATE METRICS
########################################################

echo "Collecting metrics..."

cat */outs/metrics_summary.csv > all_samples_metrics.csv

echo "Pipeline completed successfully"
