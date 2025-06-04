# DjerbaReportGenerator

Given metrics from file provenance, the workflow will create an intermediate INI file and run djerba to generate RUO reports.

## Overview

## Dependencies

* [pandas 2.1.3](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/60_pandas.yaml?ref_type=heads)
* [gsi-qc-etl 1.36](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/80_gsiqcetl.yaml?ref_type=heads)
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
`report_files`|ReportInputFiles|Struct containing paths to input files required for Djerba report generation
`patient_study_id`|String|Patient identifier
`LIMS_ID`|Array[String]|Array of LIMS IDs


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`outputFileNamePrefix`|String|donor|Output prefix, customizable based on donor


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`queryCallability.modules`|String|"gsi-qc-etl/1.36"|Name and version of module to be loaded
`queryCallability.timeout`|Int|5|Timeout in hours
`queryCallability.jobMemory`|Int|12|Memory in Gb for this job
`queryCoverage.modules`|String|"gsi-qc-etl/1.36"|Name and version of module to be loaded
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


## Commands
 This section lists command(s) run by DjerbaReportGenerator workflow
 
 * Running DjerbaReportGenerator
 
 DjerbaReportGenerator creates RUO Reports by generating intermediate INI files and running Djerba 1.9.2. 
 
 
 Retrieve callability from mutectcallability qc-etl cache
 
 ```
     LIMS_IDS="~{sep=" " LIMS_ID}"
     python3 ~{python_script} --lims-id $LIMS_IDS --gsiqcetl-dir ~{active_cache} --gsiqcetl-dir ~{archival_cache}
 ```
 
 Retrieve coverage_deduplicated from bamqc4merged qc-etl cache
 
 ```
     LIMS_IDS="~{sep=" " LIMS_ID}"
     python3 ~{python_script} --lims-id $LIMS_IDS --gsiqcetl-dir ~{active_cache} --gsiqcetl-dir ~{archival_cache}
 ```
 
 Create the intermediate INI file 
 
 ```
     python3 ~{python_script} \
         ~{project} \
         ~{study} \
         ~{donor} \
         ~{report_id} \
         ~{assay} \
         ~{tumor_id} \
         ~{normal_id} \
         ~{purple_zip} \
         ~{msi_file} \
         ~{ctdna_file} \
         ~{hrd_path} \
         ~{patient_study_id} \
         ~{maf_path} \
         ~{mavis_path} \
         ~{arriba_path} \
         ~{rsem_genes_results} \
         ~{callability} \
         ~{mean_coverage}
 ```
 
 Create sample_info.json and provenanve_subset.tsv.gz file
 
 ```
 cat <<EOF > sample_info.json
         {
         "project": "~{project}",
         "donor": "~{donor}",
         "patient_study_id": "~{patient_study_id}",
         "tumour_id": "~{tumor_id}",
         "normal_id": "~{normal_id}",
         "sample_name_tumour": "~{sample_name_tumor}",
         "sample_name_normal": "~{sample_name_normal}",
         "sample_name_aux": "~{sample_name_aux}"
         }
     EOF
 
 cat <<EOF > provenance_subset.tsv.gz
 EOF
 ```
 
 Run Djerba 1.9.2
 
 ```
    mkdir -p ~{Prefix}
    mv ~{sample_info} ~{Prefix}
    mv ~{provenance_subset} ~{Prefix}
 
    $DJERBA_ROOT/bin/djerba.py report \
        -i ~{ini_file} \
        -o ~{Prefix} \
        --pdf \
        --no-archive
 ```
 
 
 ## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
