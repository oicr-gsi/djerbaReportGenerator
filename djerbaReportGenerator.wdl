version 1.0

struct WgtsInput {
    File? purpleZip
    File? msiFile
    File? hrdPath
    File? mafPath
    File? mavisPath
    File? arribaPath
    File? rsemGenesResults
}

struct WgsInput {
    File? purpleZip
    File? msiFile
    File? hrdPath
    File? mafPath
}

struct TarInput {
    File? ichorcnaFile
    File? mafFile
    File? segFile
    File? plotsFile
}

struct PwgsInput {
    File? resultsFile
    File? vafFile
    File? hbcFile
    File? bamqcResults
    File? candidateSnvCount
}

workflow djerbaReportGenerator {
    input {
        String project
        String study
        String donor
        String reportId
        String assay
        String? tumourId
        String? normalId
        String attributes
        String? sampleNameTumour
        String? sampleNameNormal
        String? sampleNameAux
        String? cbioId
        String? groupId
        String? wgsReportId
        String patientStudyId
        String CaseId
        WgtsInput wgtsFiles
        WgsInput wgsFiles
        TarInput tarFiles
        PwgsInput pwgsFiles
        String outputFileNamePrefix = donor
    }

    parameter_meta {
        project: "Project name"
        study: "Study"
        donor: "Donor"
        reportId: "Report identifier"
        assay: "Assay name"
        tumourId: "Tumour sample identifier"
        normalId: "Matched normal sample identifier"
        attributes: "research or clinical"
        sampleNameTumour: "Sample name for the tumour WG sample"
        sampleNameNormal: "Sample name for the normal WG sample"
        sampleNameAux: "Sample name for tumour transcriptome (WT)"
        cbioId: "Assay type"
        groupId: "External sample identifier"
        wgsReportId: "WGS assay report identifier"
        wgtsFiles: "Struct containing optional file paths for the WGTS assay"
        wgsFiles: "Struct containing optional file paths for the WGS assay"
        tarFiles: "Struct containing optional file paths for the TAR assay"
        pwgsFiles: "Struct containing optional file paths for the PWGS assay"
        patientStudyId: "Patient identifier"
        CaseId: "Case Identifier"
        outputFileNamePrefix: "Output prefix, customizable based on donor"
    }

    meta {
        author: "Aditi Nagaraj Nallan"
        email: "anallan@oicr.on.ca"
        description: "Given metrics, the workflow will create an intermediate INI file and run djerba to generate Clinical and RUO reports."
        dependencies: [
            {
                name: "djerbareporter/2.0.0",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/"
            },
            {
                name: "cromwell-tools/3.0",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/"
            },
            {
                name: "python/3.13.0",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/"
            },
            {
                name: "djerba/1.13.0",
                url: "https://github.com/oicr-gsi/djerba"
            }
        ]
        output_meta: {
            reportOutput: {
                description: "The djerba output folder",
                vidarr_label: "reportOutput"
            }
        }
    }

    # queryCallability only if WGTS or WGS
    if (assay == "WGTS" || assay == "WGS") {
        call queryCallability {
            input:
                CaseId = CaseId
                }
    }

    call queryCoverage {
        input:
            CaseId = CaseId,
            assay = assay
        }

    Map[String, String] default = {"callability": "0"}

    String create_ini_args =
        if assay == "PWGS" then
            "--group_id \"~{groupId}\" --mean_coverage \"~{queryCoverage.coverageResult["meanCoverage"]}\"  --wgs_report_id \"~{wgsReportId}\" --median_insert_size \"~{queryCoverage.coverageResult["medianInsertSize"]}\""
            + (if defined(pwgsFiles.resultsFile) then " --results_file \"~{pwgsFiles.resultsFile}\"" else "")
            + (if defined(pwgsFiles.vafFile) then " --vaf_file \"~{pwgsFiles.vafFile}\"" else "")
            + (if defined(pwgsFiles.hbcFile) then " --hbc_file \"~{pwgsFiles.hbcFile}\"" else "")
            + (if defined(pwgsFiles.bamqcResults) then " --bamqc_results \"~{pwgsFiles.bamqcResults}\"" else "")
            + (if defined(pwgsFiles.candidateSnvCount) then " --candidate_snv_count \"~{pwgsFiles.candidateSnvCount}\"" else "")
        else if assay == "TAR" then
            "--tumour_id \"~{tumourId}\" --raw_coverage \"~{queryCoverage.coverageResult["rawCoverage"]}\" --collapsed_coverage \"~{queryCoverage.coverageResult["collapsedCoverage"]}\" --normal_id \"~{normalId}\" --cbioId \"~{cbioId}\""
            + (if defined(tarFiles.ichorcnaFile) then " --ichorcna_file \"~{tarFiles.ichorcnaFile}\"" else "")
            + (if defined(tarFiles.mafFile) then " --maf_file \"~{tarFiles.mafFile}\"" else "")
            + (if defined(tarFiles.segFile) then " --seg_file \"~{tarFiles.segFile}\"" else "")
            + (if defined(tarFiles.plotsFile) then " --plots_file \"~{tarFiles.plotsFile}\"" else "")
            + " --group_id \"~{groupId}\""
        else if assay == "WGTS" then
            "--tumour_id \"~{tumourId}\" --mean_coverage \"~{queryCoverage.coverageResult["meanCoverage"]}\" --normal_id \"~{normalId}\""
            + (if defined(wgtsFiles.purpleZip) then " --purple_zip \"~{wgtsFiles.purpleZip}\"" else "")
            + (if defined(wgtsFiles.msiFile) then " --msi_file \"~{wgtsFiles.msiFile}\"" else "")
            + (if defined(wgtsFiles.hrdPath) then " --hrd_path \"~{wgtsFiles.hrdPath}\"" else "")
            + (if defined(wgtsFiles.mafPath) then " --maf_path \"~{wgtsFiles.mafPath}\"" else "")
            + (if defined(wgtsFiles.mavisPath) then " --mavis_path \"~{wgtsFiles.mavisPath}\"" else "")
            + (if defined(wgtsFiles.arribaPath) then " --arriba_path \"~{wgtsFiles.arribaPath}\"" else "")
            + (if defined(wgtsFiles.rsemGenesResults) then " --rsem_genes_results \"~{wgtsFiles.rsemGenesResults}\"" else "")
            + " --callability \"~{select_first([queryCallability.callabilityResult, default])["callability"]}\""
        else if assay == "WGS" then
            "--tumour_id \"~{tumourId}\" --mean_coverage \"~{queryCoverage.coverageResult["meanCoverage"]}\" --normal_id \"~{normalId}\""
            + (if defined(wgsFiles.purpleZip) then " --purple_zip \"~{wgsFiles.purpleZip}\"" else "")
            + (if defined(wgsFiles.msiFile) then " --msi_file \"~{wgsFiles.msiFile}\"" else "")
            + (if defined(wgsFiles.hrdPath) then " --hrd_path \"~{wgsFiles.hrdPath}\"" else "")
            + (if defined(wgsFiles.mafPath) then " --maf_path \"~{wgsFiles.mafPath}\"" else "")
            + " --callability \"~{select_first([queryCallability.callabilityResult, default])["callability"]}\"" 
        else
            ""

    call createINI {
        input:
            project = project,
            donor = donor,
            study = study,
            reportId = reportId,
            assay = assay,
            patientStudyId = patientStudyId,
            attributes = attributes,
            template_dir = "/.mounts/labs/gsi/modulator/sw/Ubuntu20.04/djerba-1.13.0/lib/python3.13/site-packages/djerba/plugins/supplement/body",
            createArgs = create_ini_args
    }

    if (assay == "WGTS"|| assay == "WGS") {
        call createIntermediaries {
            input:
                project = project,
                donor = donor,
                patientStudyId = patientStudyId,
                tumourId = select_first([tumourId, ""]),
                normalId = select_first([normalId, ""]),
                sampleNameTumour = select_first([sampleNameTumour, ""]),
                sampleNameNormal = select_first([sampleNameNormal, ""]),
                sampleNameAux = select_first([sampleNameAux, ""])
        }
    }

    call runDjerba {
        input:
            assay = assay,
            project = project,
            attributes = attributes,
            Prefix = outputFileNamePrefix,
            reportId = reportId,
            iniFile = createINI.iniFile,
            sampleInfo = createIntermediaries.sampleInfo,
            provenanceSubset = createIntermediaries.provenanceSubset
    }

    output {
        File reportOutput = runDjerba.reportDir
    }
}

task queryCallability {
    input {
        String CaseId
        String modules = "djerbareporter/2.0.0 cromwell-tools/3.0"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        CaseId: "The Case Identifier that will be used to query cardea"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        set -euo pipefail
        python3 $DJERBAREPORTER_ROOT/share/callSearch.py --case-id ~{CaseId} 
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        Map[String, String] callabilityResult = read_json("result.json")
    }
}

task queryCoverage {
    input {
        String CaseId
        String assay
        String modules = "djerbareporter/2.0.0 cromwell-tools/3.0"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        CaseId: "The Case Identifier that will be used to query cardea"
        assay: "Assay name"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        set -euo pipefail
        python3 $DJERBAREPORTER_ROOT/share/covSearch.py --case-id ~{CaseId} --assay ~{assay}
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        Map[String, String] coverageResult = read_json("result.json")
    }
}

task createINI {
    input {
        String project
        String study
        String donor
        String reportId
        String assay
        String patientStudyId
        String attributes
        String createArgs 
        String template_dir
        String modules = "djerbareporter/2.0.0"
        Int timeout = 4
        Int jobMemory = 2
    }

    parameter_meta {
        project: "Project name"
        study: "Study"
        donor: "Donor"
        reportId: "Report identifier"
        assay: "Assay name"
        attributes: "research or clinical"
        patientStudyId: "Patient identifier"
        template_dir: "Path to the djerba supplement directory"
        createArgs: "Arguments to pass to the script"
        modules: "Name and version of module to be loaded"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
    }

    command <<<
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
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        File iniFile = "djerba_input.ini"
    }
}

task createIntermediaries {
    input {
        String project
        String donor
        String patientStudyId
        String tumourId
        String normalId
        String sampleNameTumour
        String sampleNameNormal
        String sampleNameAux
    }

    parameter_meta {
        project: "Project name"
        donor: "Donor"
        patientStudyId: "Patient identifier"
        tumourId: "Tumour sample identifier"
        normalId: "Matched normal sample identifier"
        sampleNameTumour: "Sample name for the tumour WG sample"
        sampleNameNormal: "Sample name for the normal WG sample"
        sampleNameAux: "Sample name for tumour transcriptome (WT)"
    }

    command <<<
        set -euo pipefail
        cat <<EOF > sample_info.json
            {
            "project": "~{project}",
            "donor": "~{donor}",
            "patient_study_id": "~{patientStudyId}",
            "tumour_id": "~{tumourId}",
            "normal_id": "~{normalId}",
            "sample_name_tumour": "~{sampleNameTumour}",
            "sample_name_normal": "~{sampleNameNormal}",
            "sample_name_aux": "~{sampleNameAux}"
            }
        EOF

        cat <<EOF > provenance_subset.tsv.gz
        EOF
    >>>

    output {
        File sampleInfo = "sample_info.json"
        File provenanceSubset = "provenance_subset.tsv.gz"
    }
}

task runDjerba {
    input {
        String Prefix
        String assay
        String project
        String attributes
        String reportId
        File iniFile
        File? sampleInfo
        File? provenanceSubset
        String modules = "djerbareporter/2.0.0 djerba/1.13.0" 
        Int timeout = 10
        Int jobMemory = 30
    }

    parameter_meta {
        Prefix: "Prefix for the output files"
        assay: "Name of assay"
        project: "Name of the project"
        attributes: "research or clinical"
        reportId: "Report identifier"
        iniFile: "The INI input for Djerba"
        sampleInfo: "Intermediate file with sample information"
        provenanceSubset: "Intermediate empty file required to run Djerba"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
        modules: "Name and version of module to be loaded"
    }

    command <<<
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
            $DJERBA_ROOT/bin/djerba.py update -j ~{Prefix}/~{reportId}_report.json -o ~{Prefix} -s ~{Prefix}/results_summary.txt -p 
        fi

        if [[ "~{attributes}" == "clinical" && ( "~{assay}" == "WGTS" || "~{assay}" == "WGS" ) ]]; then
            python3 $DJERBAREPORTER_ROOT/share/blurbomatic.py < ~{Prefix}/~{reportId}_report.json > ~{Prefix}/results_summary.txt
            $DJERBA_ROOT/bin/djerba.py update -j ~{Prefix}/~{reportId}_report.json -o ~{Prefix} -s ~{Prefix}/results_summary.txt -p 
        fi

        #Copy .ini file into final output directory
        cp -L -- "~{iniFile}" "~{Prefix}/djerba_input.ini"

        #Compress output dir
        tar -cvzf ~{Prefix}.tar.gz ~{Prefix}
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        File reportDir = "~{Prefix}.tar.gz"
    }
}