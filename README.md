# DjerbaReportGenerator

Given metrics from file provenance, the workflow will create an intermediate INI file and run djerba to generate RUO reports.

## Overview

## Dependencies

* [pandas 2.1.3](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/60_pandas.yaml?ref_type=heads)
* [sqlite3 3.39.3](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/70_sqlite.yaml?ref_type=heads)
* [djerba 1.9.2](https://github.com/oicr-gsi/djerba)


## Usage

### Cromwell
```
java -jar cromwell.jar run DjerbaReportGenerator.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`project`|String|Project name
`study`|String|Study
`donor`|String|Donor
`report_id`|String|Report identifier
`assay`|String|Assay name
`tumor_id`|String|Tumor sample identifier
`normal_id`|String|Matched normal sample identifier
`sample_name_tumor`|String|Sample name for the tumour WG sample
`sample_name_normal`|String|Sample name for the normal WG sample
`sample_name_aux`|String|Sample name for tumor transcriptome (WT)
`purple_zip`|File|Path to purple output
`msi_file`|File|Path to msi output
`ctdna_file`|File|Path to SNP counts
`hrd_path`|File|Path to genomic signatures
`patient_study_id`|String|Patient identifier
`maf_path`|File|Path to mutect2 output
`mavis_path`|File|Path to mavis output
`arriba_path`|File|Path to gene fusion output
`rsem_genes_results`|File|Path to rsem output
`LIMS_ID`|Array[String]|Array of LIMS IDs


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`outputFileNamePrefix`|String|donor|Output prefix, customizable based on donor


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`queryCallability.modules`|String|"gsi-qc-etl/1.34"|Name and version of module to be loaded
`queryCallability.timeout`|Int|5|Timeout in hours
`queryCallability.jobMemory`|Int|12|Memory in Gb for this job
`queryCoverage.modules`|String|"gsi-qc-etl/1.34"|Name and version of module to be loaded
`queryCoverage.timeout`|Int|5|Timeout in hours
`queryCoverage.jobMemory`|Int|12|Memory in Gb for this job
`createINI.modules`|String|"pandas/2.1.3"|Name and version of module to be loaded
`createINI.timeout`|Int|4|Timeout in hours
`createINI.jobMemory`|Int|2|Memory in Gb for this job
`runDjerba.modules`|String|"djerba/1.9.2"|Name and version of module to be loaded
`runDjerba.timeout`|Int|10|Timeout in hours
`runDjerba.jobMemory`|Int|25|Memory in Gb for this job


### Outputs

Output | Type | Description | Labels
---|---|---|---
`reportHTML`|File|The RUO report in HTML file format|vidarr_label: reportHTML
`reportPDF`|File|The RUO report in PDF file format|vidarr_label: reportPDF
`reportJSON`|File|The RUO report in JSON file format|vidarr_label: reportJSON


./commands.txt found, printing out the content...
## Commands
 This section lists command(s) run by DjerbaReportGenerator workflow
 
 * Running DjerbaReportGenerator
 
 DjerbaReportGenerator creates RUO Reports specifically and Clinical Reports generally from fpr queried metrics by generating intermediate INI files and running Djerba 1.8.4. 
 
 
 Retrieve callability from mutectcallability qc-etl cache
 
 ```
     LIMS_IDS="~{sep=" " LIMS_ID}"
     python3 ~{python_script} $LIMS_IDS
 ```
 
 Retrieve coverage_deduplicated from bamqc4merged qc-etl cache
 
 ```
     LIMS_IDS="~{sep=" " LIMS_ID}"
     python3 ~{python_script} $LIMS_IDS
 ```
 
 Create the intermediate INI file 
 
 ```
     echo "[core]" > temp_ini_file.ini
     echo "report_id = ~{report_id}" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[input_params_helper]" >> temp_ini_file.ini
     echo "assay = WGTS" >> temp_ini_file.ini
     echo "donor = ~{donor}" >> temp_ini_file.ini
     echo "oncotree_code = NA" >> temp_ini_file.ini
     echo "primary_cancer = NA" >> temp_ini_file.ini
     echo "project = ~{project}" >> temp_ini_file.ini
     echo "requisition_approved = 2025-01-01" >> temp_ini_file.ini
     echo "requisition_id = NA" >> temp_ini_file.ini
     echo "sample_type = NA" >> temp_ini_file.ini
     echo "site_of_biopsy = NA" >> temp_ini_file.ini
     echo "study = ~{study}" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[provenance_helper]" >> temp_ini_file.ini
     echo "sample_name_tumour = ~{sample_name_tumor}" >> temp_ini_file.ini
     echo "sample_name_normal = ~{sample_name_normal}" >> temp_ini_file.ini
     echo "sample_name_aux = ~{sample_name_aux}" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[case_overview]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[sample]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
     echo "callability = ~{callability}" >> temp_ini_file.ini
     echo "mean_coverage = ~{mean_coverage}" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[genomic_landscape]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[expression_helper]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[wgts.snv_indel]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[wgts.cnv_purple]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[fusion]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[gene_information_merger]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
     echo "" >> temp_ini_file.ini
     echo "[supplement.body]" >> temp_ini_file.ini
     echo "attributes = research" >> temp_ini_file.ini
 ```
 
 Run Djerba 1.8.4
 
 ```
    mkdir -p ~{Prefix}
 
    $DJERBA_ROOT/bin/djerba.py report \
        -i ~{ini_file} \
        -o ~{Prefix} \
        --pdf \
        --no-archive
 ```
 
 
 ## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
