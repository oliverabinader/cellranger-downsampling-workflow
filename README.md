# Author: Oliver Abinader


# Single-Cell RNA-seq Cell Ranger Workflow

A standardized preprocessing and analysis workflow for single-cell RNA-seq data using Cell Ranger. This pipeline ensures uniform sequencing depth across samples through controlled downsampling and generates consistent inputs for downstream clustering and gene expression analysis.


## Overview

Cell Ranger is an industry-standard pipeline used for processing 10x Genomics single-cell RNA-seq data. It performs:

* Read alignment
* UMI counting
* Cell barcode assignment
* Gene expression matrix generation
* Secondary QC metrics generation

This workflow focuses on **preprocessing, normalization, and standardized input preparation** before Cell Ranger execution.


## Key Principles

### 1. Uniform Sequencing Depth

To ensure comparability across samples, all datasets are normalized to the **lowest sequencing depth** within the experiment.


### 2. Paired-End Data Requirement

Cell Ranger requires both:

* R1: Cell barcode + UMI information
* R2: Transcript sequence

Both reads are essential for proper molecule reconstruction.


### 3. Experimental Design Considerations

* Mock samples may have higher read depth than depleted samples
* Final downsampling depth is determined based on experimental constraints
* In some cases, expected cell numbers may require adjusting Cell Ranger parameters (e.g., expected cell recovery)


## Workflow Steps

### 1. Determine Sequencing Depth

The minimum read count across all FASTQ files is calculated to define the downsampling threshold.


### 2. Downsampling Reads

FASTQ files are downsampled to a uniform sequencing depth using random sampling.

This step ensures:

* Comparable sequencing depth across conditions
* Standardized input for Cell Ranger


### 3. Validation of Downsampling

Downsampled files are verified to confirm:

* Expected read counts are retained
* No file corruption occurred
* Paired-end structure is preserved


### 4. File Organization

Downsampled FASTQ files are reorganized by experimental condition to prepare for Cell Ranger execution.

Each condition is processed independently.


### 5. Cell Ranger Execution

Cell Ranger is run separately for each sample/condition.

Key outputs include:

* Gene-barcode matrix
* Alignment metrics
* Cell calling statistics
* QC summary reports

Optional parameter:

* `--expect-cells` can be used when higher cell recovery is expected based on experimental design


### 6. Output Aggregation

After processing, key metrics are extracted from all samples:

* Median genes per cell
* Median UMI counts per cell

These are combined into a summary table for comparative analysis.


## Key Output Files

* Cell Ranger `metrics_summary.csv` (per sample)
* Aggregated QC table (`all_samples_metrics.csv`)
* Final visualization plots


## Interpretation of Downsampling Strategy

Downsampling is used to ensure:

* Equal sequencing depth across biological replicates
* Fair comparison between mock and treated samples
* Reduced technical bias in clustering and differential expression


## Notes

* Cell Ranger is primarily used for **single-cell RNA-seq**, not bulk RNA-seq
* Downsampling decisions should be guided by experimental design and biological context
* Over-aggressive downsampling may reduce cell recovery and gene detection sensitivity
* Proper R1/R2 pairing is critical for correct UMI assignment


## Summary

This workflow standardizes single-cell RNA-seq preprocessing by:

1. Assessing sequencing depth
2. Applying uniform downsampling across samples
3. Structuring input for Cell Ranger
4. Running per-sample Cell Ranger analysis
5. Aggregating QC metrics for downstream interpretation
