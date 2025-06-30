# djerbaReportGenerator

Given metrics, the workflow will create an intermediate INI file and run djerba to generate RUO reports.

## Overview

## Dependencies

* [djerbareporter 1.0.0](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/70_djerbareporter.yaml?ref_type=heads)
* [pandas 2.1.3](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/60_pandas.yaml?ref_type=heads)
* [gsi-qc-etl 1.36](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/80_gsiqcetl.yaml?ref_type=heads)
* [djerba 1.9.2](https://github.com/oicr-gsi/djerba)


## Usage

### Cromwell
```
java -jar cromwell.jar run djerbaReportGenerator.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`project`|String|Project name
`study`|String|Study
`donor`|String|Donor
`reportId`|String|Report identifier
`assay`|String|Assay name
`tumorId`|String|Tumor sample identifier
`normalId`|String|Matched normal sample identifier
`sampleNameTumor`|String|Sample name for the tumour WG sample
`sampleNameNormal`|String|Sample name for the normal WG sample
`sampleNameAux`|String|Sample name for tumor transcriptome (WT)
`reportFiles`|ReportInputFiles|Struct containing paths to input files required for Djerba report generation
`patientStudyId`|String|Patient identifier
`LimsId`|Array[String]|Array of LIMS IDs


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`outputFileNamePrefix`|String|donor|Output prefix, customizable based on donor


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`queryCallability.modules`|String|"djerbareporter/1.0.0 gsi-qc-etl/1.36"|Name and version of module to be loaded
`queryCallability.timeout`|Int|5|Timeout in hours
`queryCallability.jobMemory`|Int|12|Memory in Gb for this job
`queryCoverage.modules`|String|"djerbareporter/1.0.0 gsi-qc-etl/1.36"|Name and version of module to be loaded
`queryCoverage.timeout`|Int|5|Timeout in hours
`queryCoverage.jobMemory`|Int|12|Memory in Gb for this job
`createINI.modules`|String|"djerbareporter/1.0.0 pandas/2.1.3"|Name and version of module to be loaded
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


anallan/repositories/djerbaReportGenerator/commands.txt found, printing out the content...
## Commands
 This section lists command(s) run by djerbaReportGenerator workflow
 
 * Running djerbaReportGenerator
 
 djerbaReportGenerator creates RUO Reports by generating intermediate INI files and running Djerba 1.9.2. 
 
 
 Retrieve callability from mutectcallability qc-etl cache
 
 ```
     LimsId="~{sep=" " LimsId}"
     callSearch --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache}
 ```
 
 Retrieve coverage_deduplicated from bamqc4merged qc-etl cache
 
 ```
     LimsId="~{sep=" " LimsId}"
     covSearch --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache}
 ```
 
 Create the intermediate INI file 
 
 ```
     createIni \
         "~{project}" \
         "~{study}" \
         "~{donor}" \
         "~{reportId}" \
         "~{assay}" \
         "~{tumorId}" \
         "~{normalId}" \
         "~{purpleZip}" \
         "~{msiFile}" \
         "~{ctdnaFile}" \
         "~{hrdPath}" \
         "~{patientStudyId}" \
         "~{mafPath}" \
         "~{mavisPath}" \
         "~{arribaPath}" \
         "~{rsemGenesResults}" \
         "~{callability}" \
         "~{meanCoverage}"
 ```
 
 Create sample_info.json and provenanve_subset.tsv.gz file
 
 ```
 cat <<EOF > sample_info.json
         {
         "project": "~{project}",
         "donor": "~{donor}",
         "patientStudyId": "~{patientStudyId}",
         "tumourId": "~{tumorId}",
         "normalId": "~{normalId}",
         "sampleNameTumour": "~{sampleNameTumor}",
         "sampleNameNormal": "~{sampleNameNormal}",
         "sampleNameAux": "~{sampleNameAux}"
         }
     EOF
 
 cat <<EOF > provenance_subset.tsv.gz
 EOF
 ```
 
 Run Djerba 1.9.2
 
 ```
    mkdir -p ~{Prefix}
    mv ~{sampleInfo} ~{Prefix}
    mv ~{provenanceSubset} ~{Prefix}
    export DJERBA_PRIVATE_DIR=/.mounts/labs/gsiprojects/gsi/CGI/resources
 
    $DJERBA_ROOT/bin/djerba.py report \
        -i ~{iniFile} \
        -o ~{Prefix} \
        --pdf \
        --no-archive
 ```
 
 
 ## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_