version 1.0

struct WgtsInput {
    String purpleZip
    String msiFile
    String ctdnaFile
    String hrdPath
    String mafPath
    String mavisPath
    String arribaPath
    String rsemGenesResults
}

struct TarInput {
    String ichorcnaFile
    String consensuscruncherFile
    String consensuscruncherFileNormal
    String mafFile
    String mafFileNormal
    String segFile
    String plotsFile
}

struct PwgsInput {
    String resultsFile
    String vafFile
    String hbcFile
    String bamqcResults
    String candidateSnvCount
}

workflow djerbaReportGenerator {
    input {
        String project
        String study
        String donor
        String reportId
        String assay
        String? tumorId
        String? normalId
        String attributes
        String? sampleNameTumor
        String? sampleNameNormal
        String? sampleNameAux
        String? cbioId
        String? groupId
        String? wgsReportId
        String patientStudyId
        Array[String] LimsId
        WgtsInput wgtsFiles
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
        tumorId: "Tumor sample identifier"
        normalId: "Matched normal sample identifier"
        attributes: "research or clinical"
        sampleNameTumor: "Sample name for the tumour WG sample"
        sampleNameNormal: "Sample name for the normal WG sample"
        sampleNameAux: "Sample name for tumor transcriptome (WT)"
        cbioId: "Assay type"
        groupId: "External sample identifier"
        wgsReportId: "WGS assay report identifier"
        wgtsFiles: "Struct containing file paths from the WGTS assay"
        tarFiles: "Struct containing file paths from the TAR assay"
        pwgsFiles: "Struct containing file paths from the PWGS assay"
        patientStudyId: "Patient identifier"
        LimsId: "Array of LIMS IDs"
        outputFileNamePrefix: "Output prefix, customizable based on donor"
    }

    meta {
        author: "Aditi Nagaraj Nallan"
        email: "anallan@oicr.on.ca"
        description: "Given metrics, the workflow will create an intermediate INI file and run djerba to generate RUO reports."
        dependencies: [
            {
                name: "djerbareporter/1.0.0",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/70_djerbareporter.yaml?ref_type=heads"
            },
            {
                name : "pandas/2.1.3",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/60_pandas.yaml?ref_type=heads"
            },
            {
                name : "gsi-qc-etl/1.38",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/80_gsiqcetl.yaml?ref_type=heads"
            },
            {
                name : "djerba/1.10.2",
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

    # queryCallability only if WGTS
    if (assay == "WGTS") {
        call queryCallability {
            input:
                LimsId = LimsId,
                activeCache = "/scratch2/groups/gsi/production/qcetl_v1",
                archivalCache = "/.mounts/labs/gsi/gsiqcetl_archival/production/ro"
        }
    }

    call queryCoverage {
        input:
            LimsId = LimsId,
            activeCache = "/scratch2/groups/gsi/production/qcetl_v1",
            archivalCache = "/.mounts/labs/gsi/gsiqcetl_archival/production/ro",
            assay = assay,
            script = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/djerbaReportGenerator/scripts/covSearch.py"
    }

    String create_ini_args =
    if assay == "PWGS" then
        "--group_id \"~{groupId}\" --wgs_report_id \"~{wgsReportId}\" --median_insert_size \"~{queryCoverage.medianInsertSize}\" --results_file \"~{pwgsFiles.resultsFile}\" --vaf_file \"~{pwgsFiles.vafFile}\" --hbc_file \"~{pwgsFiles.hbcFile}\" --bamqc_results \"~{pwgsFiles.bamqcResults}\" --candidate_snv_count \"~{pwgsFiles.candidateSnvCount}\""
    else if assay == "TAR" then
        "--tumor_id \"~{tumorId}\" --normal_id \"~{normalId}\" --cbioId \"~{cbioId}\" --ichorcna_file \"~{tarFiles.ichorcnaFile}\" --consensuscruncher_file \"~{tarFiles.consensuscruncherFile}\" --consensuscruncher_file_normal \"~{tarFiles.consensuscruncherFileNormal}\" --maf_file \"~{tarFiles.mafFile}\" --maf_file_normal \"~{tarFiles.mafFileNormal}\" --seg_file \"~{tarFiles.segFile}\" --plots_file \"~{tarFiles.plotsFile}\" --group_id \"~{groupId}\""
    else
        "--tumor_id \"~{tumorId}\" --normal_id \"~{normalId}\" --purple_zip \"~{wgtsFiles.purpleZip}\" --msi_file \"~{wgtsFiles.msiFile}\" --ctdna_file \"~{wgtsFiles.ctdnaFile}\" --hrd_path \"~{wgtsFiles.hrdPath}\" --maf_path \"~{wgtsFiles.mafPath}\" --mavis_path \"~{wgtsFiles.mavisPath}\" --arriba_path \"~{wgtsFiles.arribaPath}\" --rsem_genes_results \"~{wgtsFiles.rsemGenesResults}\" --callability \"~{queryCallability.callability}\""


    call createINI {
        input:
            project = project,
            donor = donor,
            study = study,
            reportId = reportId,
            assay = assay,
            patientStudyId = patientStudyId,
            meanCoverage = queryCoverage.meanCoverage,
            attributes = attributes,
            createArgs = create_ini_args,
            script = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/djerbaReportGenerator/scripts/createINI.py"
    }

    if (assay == "WGTS") {
        call createIntermediaries {
            input:
                project = project,
                donor = donor,
                patientStudyId = patientStudyId,
                tumorId = select_first([tumorId, ""]),
                normalId = select_first([normalId, ""]),
                sampleNameTumor = select_first([sampleNameTumor, ""]),
                sampleNameNormal = select_first([sampleNameNormal, ""]),
                sampleNameAux = select_first([sampleNameAux, ""])
        }
    }

    call runDjerba {
        input:
            assay = assay,
            Prefix = outputFileNamePrefix,
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
        Array[String] LimsId
        String activeCache
        String archivalCache
        String modules = "djerbareporter/1.0.0"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        LimsId: "The LIMS Identifiers that will be used to query the cache"
        activeCache: "Path to the qc etl cache for active projects"
        archivalCache: "Path to the qc etl cache for all active and inactive projects"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        LimsId="~{sep=" " LimsId}"
        callSearch --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache}
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        String callability = read_string("callability.txt")
    }
}

task queryCoverage {
    input {
        Array[String] LimsId
        String activeCache
        String archivalCache
        String assay
        String script
        String modules = "djerbareporter/1.0.0"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        LimsId: "The LIMS Identifiers that will be used to query the cache"
        activeCache: "Path to the qc etl cache for active projects"
        archivalCache: "Path to the qc etl cache for all active and inactive projects"
        assay: "Assay name"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        LimsId="~{sep=" " LimsId}"
        python3 ~{script} --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache} --assay ~{assay}
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        String meanCoverage = read_string("coverage.txt")
        String? medianInsertSize = read_string("insertsize.txt")
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
        String meanCoverage
        String attributes
        String createArgs 
        String script
        String modules = "djerbareporter/1.0.0"
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
        createArgs: "Arguments to pass to the script"
        script: "Path to the createIni.py script"
        meanCoverage: "Mean coverage value from queryCoverage task"
        modules: "Name and version of module to be loaded"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
    }

    command <<<
        python3 ~{script} \
            "~{project}" \
            "~{study}" \
            "~{donor}" \
            "~{reportId}" \
            "~{assay}" \
            "~{patientStudyId}" \
            "~{meanCoverage}" \
            "~{attributes}" \
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
        String tumorId
        String normalId
        String sampleNameTumor
        String sampleNameNormal
        String sampleNameAux
    }

    parameter_meta {
        project: "Project name"
        donor: "Donor"
        patientStudyId: "Patient identifier"
        tumorId: "Tumor sample identifier"
        normalId: "Matched normal sample identifier"
        sampleNameTumor: "Sample name for the tumor WG sample"
        sampleNameNormal: "Sample name for the normal WG sample"
        sampleNameAux: "Sample name for tumor transcriptome (WT)"
    }

    command <<<
        cat <<EOF > sample_info.json
            {
            "project": "~{project}",
            "donor": "~{donor}",
            "patient_study_id": "~{patientStudyId}",
            "tumour_id": "~{tumorId}",
            "normal_id": "~{normalId}",
            "sample_name_tumour": "~{sampleNameTumor}",
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
        File iniFile
        File? sampleInfo
        File? provenanceSubset
        String modules = "djerba/1.10.2"
        Int timeout = 10
        Int jobMemory = 25
    }

    parameter_meta {
        Prefix: "Prefix for the output files"
        assay: "Name of assay"
        iniFile: "The INI input for Djerba"
        sampleInfo: "Intermediate file with sample information"
        provenanceSubset: "Intermediate empty file required to run Djerba"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
        modules: "Name and version of module to be loaded"
    }

    command <<<
        mkdir -p ~{Prefix}

        if [[ "~{assay}" == "WGTS" ]]; then
            mv ~{sampleInfo} ~{Prefix}
            mv ~{provenanceSubset} ~{Prefix}
        fi

        export ONCOKB_TOKEN=/.mounts/labs/gsiprojects/gsi/CGI/resources/.oncokb_api_token
        
        $DJERBA_ROOT/bin/djerba.py report \
            -i ~{iniFile} \
            -o ~{Prefix} \
            --pdf \
            --no-archive 
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        File reportDir = "./~{Prefix}"
    }
}