# djerbaReportGenerator

Given metrics, the workflow will create an intermediate INI file and run djerba to generate Clinical or RUO reports. 

## Overview

## Dependencies

* [djerbareporter 1.0.0](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/70_djerbareporter.yaml?ref_type=heads)
* [pandas 2.1.3](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/60_pandas.yaml?ref_type=heads)
* [gsi-qc-etl 1.38](https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/80_gsiqcetl.yaml?ref_type=heads)
* [djerba 1.11.1](https://github.com/oicr-gsi/djerba)


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
`attributes`|String|Research or Clinical
`patientStudyId`|String|Patient identifier
`LimsId`|Array[String]|Array of LIMS IDs
`wgtsFiles`|WgtsInput|Struct containing optional file paths for the WGTS assay
`wgsFiles`|WgsInput|Struct containing optional file paths for the WGS assay
`tarFiles`|TarInput|Struct containing optional file paths for the TS assay
`pwgsFiles`|PwgsInput|Struct containing optional file paths for the pWGS assay


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`tumorId`|String?|None|Tumor sample identifier
`normalId`|String?|None|Matched normal sample identifier
`sampleNameTumor`|String?|None|Sample name for the tumour WG sample
`sampleNameNormal`|String?|None|Sample name for the normal WG sample
`sampleNameAux`|String?|None|Sample name for tumor transcriptome (WT)
`cbioId`|String?|None|TS Assay ID
`groupId`|String?|None|External sample identifier
`wgsReportId`|String?|None|WGS assay identifier
`outputFileNamePrefix`|String|donor|Output prefix, customizable based on donor


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`queryCallability.modules`|String|"djerbareporter/1.0.0"|Name and version of module to be loaded
`queryCallability.timeout`|Int|5|Timeout in hours
`queryCallability.jobMemory`|Int|12|Memory in Gb for this job
`queryCoverage.modules`|String|"djerbareporter/1.0.0"|Name and version of module to be loaded
`queryCoverage.timeout`|Int|5|Timeout in hours
`queryCoverage.jobMemory`|Int|12|Memory in Gb for this job
`createINI.modules`|String|"djerbareporter/1.0.0"|Name and version of module to be loaded
`createINI.timeout`|Int|4|Timeout in hours
`createINI.jobMemory`|Int|2|Memory in Gb for this job
`runDjerba.modules`|String|"djerba/1.11.1"|Name and version of module to be loaded
`runDjerba.timeout`|Int|10|Timeout in hours
`runDjerba.jobMemory`|Int|25|Memory in Gb for this job


### Outputs

Output | Type | Description | Labels
---|---|---|---
`reportOutput`|File|The djerba output folder compressed to tar.gz|vidarr_label: reportOutput


./commands.txt found, printing out the content...
## Commands
 This section lists command(s) run by djerbaReportGenerator workflow
 
 * Running djerbaReportGenerator
 
 djerbaReportGenerator creates clinical and RUO djerba reports by generating intermediate INI files and running Djerba 1.11.1. 
 
 
 Retrieve callability from mutectcallability qc-etl cache if assay type is WGTS or WGS
 
 ```
     LimsId="~{sep=" " LimsId}"
     callSearch --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache}
 ```
 
 Retrieve median_insert_size and coverage_deduplicated from bamqc4merged or hsmetrics qc-etl cache depending on assay type
 
 ```
     LimsId="~{sep=" " LimsId}"
     covSearch --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache} --assay ~{assay}
 ```
 
 Create the intermediate INI file 
 
 ```
     createINI \
             ~{project} \
             ~{study} \
             ~{donor} \
             ~{reportId} \
             ~{assay} \
             ~{patientStudyId} \
             ~{meanCoverage} \
             ~{attributes} \
             ~{template_dir} \
             ~{createArgs}
 ```
 
 Create sample_info.json and provenanve_subset.tsv.gz file if assay type is WGS or WGTS
 
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
 
 Run Djerba 1.11.1
 
 ```
    mkdir -p ~{Prefix}
 
         if [[ ~{assay} == "WGTS" || ~{assay} == "WGS" ]]; then
             mv ~{sampleInfo} ~{Prefix}
             mv ~{provenanceSubset} ~{Prefix}
         fi
 
         export ONCOKB_TOKEN=/.mounts/labs/gsiprojects/gsi/CGI/resources/.oncokb_api_token
         
         $DJERBA_ROOT/bin/djerba.py report \
             -i ~{iniFile} \
             -o ~{Prefix} \
             --pdf \
             --no-archive 
             
         # Compress output dir
         tar -cvzf ~{Prefix}.tar.gz ~{Prefix}
 ```
 
 
 ## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_