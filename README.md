# djerbaReportGenerator

Given metrics, the workflow will create an intermediate INI file and run djerba to generate Clinical and RUO reports.

## Overview

## Dependencies

* [djerbareporter 2.0.0](https://gitlab.oicr.on.ca/ResearchIT/modulator/)
* [python 3.13.0](https://gitlab.oicr.on.ca/ResearchIT/modulator/)
* [djerba 1.13.0](https://github.com/oicr-gsi/djerba)


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
`attributes`|String|research or clinical
`patientStudyId`|String|Patient identifier
`CaseId`|String|Case Identifier
`wgtsFiles`|WgtsInput|Struct containing optional file paths for the WGTS assay
`wgsFiles`|WgsInput|Struct containing optional file paths for the WGS assay
`tarFiles`|TarInput|Struct containing optional file paths for the TAR assay
`pwgsFiles`|PwgsInput|Struct containing optional file paths for the PWGS assay


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`tumourId`|String?|None|Tumour sample identifier
`normalId`|String?|None|Matched normal sample identifier
`sampleNameTumour`|String?|None|Sample name for the tumour WG sample
`sampleNameNormal`|String?|None|Sample name for the normal WG sample
`sampleNameAux`|String?|None|Sample name for tumour transcriptome (WT)
`cbioId`|String?|None|Assay type
`groupId`|String?|None|External sample identifier
`wgsReportId`|String?|None|WGS assay report identifier
`outputFileNamePrefix`|String|donor|Output prefix, customizable based on donor


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`queryCallability.modules`|String|"djerbareporter/2.0.0"|Name and version of module to be loaded
`queryCallability.timeout`|Int|5|Timeout in hours
`queryCallability.jobMemory`|Int|12|Memory in Gb for this job
`queryCoverage.modules`|String|"djerbareporter/2.0.0"|Name and version of module to be loaded
`queryCoverage.timeout`|Int|5|Timeout in hours
`queryCoverage.jobMemory`|Int|12|Memory in Gb for this job
`createINI.modules`|String|"djerbareporter/2.0.0"|Name and version of module to be loaded
`createINI.timeout`|Int|4|Timeout in hours
`createINI.jobMemory`|Int|2|Memory in Gb for this job
`runDjerba.modules`|String|"djerbareporter/2.0.0 djerba/1.13.0"|Name and version of module to be loaded
`runDjerba.timeout`|Int|10|Timeout in hours
`runDjerba.jobMemory`|Int|25|Memory in Gb for this job


### Outputs

Output | Type | Description | Labels
---|---|---|---
`reportOutput`|File|The djerba output folder|vidarr_label: reportOutput


## Commands
 This section lists command(s) run by djerbaReportGenerator workflow
 
 * Running djerbaReportGenerator
 
 djerbaReportGenerator creates clinical and RUO djerba reports by generating intermediate INI files and running Djerba. 
 
 
 Retrieve callability if assay type is WGTS or WGS
 
 ```
     set -euo pipefail
     python3 $DJERBAREPORTER_ROOT/share/callSearch.py --case-id ~{CaseId}
 ```
 
 Retrieve median_insert_size and coverage_deduplicated for PWGS assay, coverage_deduplicated for WG(T)S assay and raw_coverage and collapsed_coverage for TAR assay. 
 
 ```
     set -euo pipefail
     python3 $DJERBAREPORTER_ROOT/share/covSearch.py --case-id ~{CaseId} --assay ~{assay}
 ```
 
 Create the intermediate INI file 
 
 ```
     set -euo pipefail
         python3 $DJERBAREPORTER_ROOT/share/createINI.py \
             --project "~{project}" \
             --study "~{study}" \
             --donor "~{donor}" \
             --report_id "~{reportId}" \
             --assay "~{assay}" \
             --patient_study_id "~{patientStudyId}" \
             --attributes "~{attributes}" \
             --template_dir "~{template_dir}" \
             ~{createArgs}
 ```
 
 Create sample_info.json and provenanve_subset.tsv.gz file if assay type is WGS or WGTS
 
 ```
 cat <<EOF > sample_info.json
         {
         "project": "~{project}",
         "donor": "~{donor}",
         "patientStudyId": "~{patientStudyId}",
         "tumourId": "~{tumourId}",
         "normalId": "~{normalId}",
         "sampleNameTumour": "~{sampleNameTumour}",
         "sampleNameNormal": "~{sampleNameNormal}",
         "sampleNameAux": "~{sampleNameAux}"
         }
     EOF
 
 cat <<EOF > provenance_subset.tsv.gz
 EOF
 ```
 
 Run Djerba
 
 ```
    set -euo pipefail
         mkdir -p ~{Prefix}
 
         if [[ "~{assay}" == "WGTS" || "~{assay}" == "WGS" ]]; then    
             if [[ -n "~{sampleInfo}" ]]; then        
                 rsync -aL "~{sampleInfo}" "~{Prefix}/"    
             fi    
             if [[ -n "~{provenanceSubset}" ]]; then        
                 rsync -aL "~{provenanceSubset}" "~{Prefix}/"    
             fi
         fi
         
         export ONCOKB_TOKEN=/.mounts/labs/gsiprojects/gsi/CGI/resources/.oncokb_api_token
 
         if [[ "~{attributes}" == "research" ]]; then        
         $DJERBA_ROOT/bin/djerba.py report \
             -i ~{iniFile} \
             -o ~{Prefix} \
             --pdf \
             --no-archive 
         fi 
 
         if [[ "~{attributes}" == "clinical" ]]; then
         $DJERBA_ROOT/bin/djerba.py report \
             -i ~{iniFile} \
             -o ~{Prefix} \
             --pdf
         fi
         
         #Run blurbomatic
         if [[ "~{attributes}" == "research" ]]; then
             echo "Results summary provided after review of clinical reports. Not available for RUO reports" > ~{Prefix}/results_summary.txt
             $DJERBA_ROOT/bin/djerba.py update -j ~{Prefix}/~{reportId}_report.json -o ~{Prefix} -s ~{Prefix}/results_summary.txt -p --no-archive
         fi
 
         if [[ "~{attributes}" == "clinical" && "~{assay}" == "TAR" && "~{project}" == "CHARM2PLAS" ]]; then
             echo "The patient has been referred for the OICR Genomics targeted sequencing REVOLVE assay for early cancer detection through the CHARM2 study. The requisitioners provided one variant known from previous genetic testing which overlaps with the REVOLVE panel: ...... This mutation was confirmed as likely germline and there were no additional somatic mutations identified/Large deletions or duplications are not readily detected by this test/The HGVS cDNA nomenclature and reference sequence were not provided, so we could neither confirm nor refute the presence of the specified variant..." > ~{Prefix}/results_summary.txt
             $DJERBA_ROOT/bin/djerba.py update -j ~{Prefix}/~{reportId}_report.json -o ~{Prefix} -s ~{Prefix}/results_summary.txt -p --no-archive
         fi
 
         if [[ "~{attributes}" == "clinical" && ( "~{assay}" == "WGTS" || "~{assay}" == "WGS" ) ]]; then
             python3 $DJERBAREPORTER_ROOT/share/blurbomatic.py < ~{Prefix}/~{reportId}_report.json > ~{Prefix}/results_summary.txt
             $DJERBA_ROOT/bin/djerba.py update -j ~{Prefix}/~{reportId}_report.json -o ~{Prefix} -s ~{Prefix}/results_summary.txt -p --no-archive
         fi
 
         #Copy .ini file into final output directory
         cp -L -- "~{iniFile}" "~{Prefix}/djerba_input.ini"
 
         #Compress output dir
         tar -cvzf ~{Prefix}.tar.gz ~{Prefix}
 ```
 
 
 ## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_