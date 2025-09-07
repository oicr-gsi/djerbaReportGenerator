version 1.0

workflow djerbaReportGenerator {
    input {
        String project
        String study
        String donor
        String reportId
        String assay
        String tumorId
        String normalId
        String attributes
        String? sampleNameTumor
        String? sampleNameNormal
        String? sampleNameAux
        String? cbioId
        String? groupId
        String patientStudyId
        Array[String] LimsId
        # WGTS input files (all optional)
        File? purpleZip
        File? msiFile
        File? ctdnaFile
        File? hrdPath
        File? mafPath
        File? mavisPath
        File? arribaPath
        File? rsemGenesResults
        # TAR input files (all optional)
        File? ichorcnaFile
        File? consensuscruncherFile
        File? consensuscruncherFileNormal
        File? mafFile
        File? mafFileNormal
        File? segFile
        File? plotsFile
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
        purpleZip: "Path to purple output"
        msiFile: "Path to msi output"
        ctdnaFile: "Path to SNP counts"
        hrdPath: "Path to genome signatures"
        mafPath: "Path to mutect2 output"
        mavisPath: "Path to mavis output"
        arribaPath: "Path to gene fusion output"
        rsemGenesResults: "Path to rsem output"
        ichorcnaFile: "Path to ichorcna output"
        consensuscruncherFile: "Path to consensus cruncher output"
        consensuscruncherFileNormal: "Path to consensus cruncher output"
        mafFile: "Path to consensus cruncher output"
        mafFileNormal: "Path to consensus cruncher output"
        segFile: "Path to ichorcna output"
        plotsFile: "Path to ichorcna output"
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
                name : "gsi-qc-etl/1.36",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/80_gsiqcetl.yaml?ref_type=heads"
            },
            {
                name : "djerba/1.11.1",
                url: "https://github.com/oicr-gsi/djerba"
            }
        ]
        output_meta: {
            reportHTML: {
                description: "The RUO report in HTML file format",
                vidarr_label: "reportHTML"
            },
            reportPDF: {
                description: "The RUO report in PDF file format",
                vidarr_label: "reportPDF"
            },
            reportJSON: {
                description: "The RUO report in JSON file format",
                vidarr_label: "reportJSON"
            }
        }
    }

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
            assay = assay
    }

    call createINI {
        input:
            project = project,
            donor = donor,
            study = study,
            reportId = reportId,
            assay = assay,
            tumorId = tumorId,
            normalId = normalId,
            patientStudyId = patientStudyId,
            meanCoverage = queryCoverage.meanCoverage,
            attributes = attributes,
            # WGTS inputs
            purpleZip = if assay == "WGTS" then select_first([purpleZip, ""]) else "",
            msiFile = if assay == "WGTS" then select_first([msiFile, ""]) else "",
            ctdnaFile = if assay == "WGTS" then select_first([ctdnaFile, ""]) else "",
            hrdPath = if assay == "WGTS" then select_first([hrdPath, ""]) else "",
            mafPath = if assay == "WGTS" then select_first([mafPath, ""]) else "",
            mavisPath = if assay == "WGTS" then select_first([mavisPath, ""]) else "",
            arribaPath = if assay == "WGTS" then select_first([arribaPath, ""]) else "",
            rsemGenesResults = if assay == "WGTS" then select_first([rsemGenesResults, ""]) else "",
            callability = select_first([queryCallability.callability, ""]),
            # TAR inputs
            cbioId = select_first([cbioId, ""]),
            groupId = select_first([groupId, ""]),
            ichorcnaFile = if assay == "TAR" then select_first([ichorcnaFile, ""]) else "",
            consensuscruncherFile = if assay == "TAR" then select_first([consensuscruncherFile, ""]) else "",
            consensuscruncherFileNormal = if assay == "TAR" then select_first([consensuscruncherFileNormal, ""]) else "",
            mafFile = if assay == "TAR" then select_first([mafFile, ""]) else "",
            mafFileNormal = if assay == "TAR" then select_first([mafFileNormal, ""]) else "",
            segFile = if assay == "TAR" then select_first([segFile, ""]) else "",
            plotsFile = if assay == "TAR" then select_first([plotsFile, ""]) else ""
    }

    if (assay == "WGTS") {
        call createIntermediaries {
            input:
                project = project,
                donor = donor,
                patientStudyId = patientStudyId,
                tumorId = tumorId,
                normalId = normalId,
                sampleNameTumor = select_first([sampleNameTumor, ""]),
                sampleNameNormal = select_first([sampleNameNormal, ""]),
                sampleNameAux = select_first([sampleNameAux, ""])    
        }
    }

    call runDjerba {
        input:
            Prefix = outputFileNamePrefix,
            iniFile = createINI.iniFile,
            sampleInfo = select_first([createIntermediaries.sampleInfo, "empty_sample_info.json"]),
            provenanceSubset = select_first([createIntermediaries.provenanceSubset, "empty_provenance_subset.tsv.gz"])
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
        String modules = "djerbareporter/1.0.0 gsi-qc-etl/1.36"
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
        String modules = "djerbareporter/1.0.0 gsi-qc-etl/1.36"
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
        covSearch --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache} --assay ~{assay}
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        String meanCoverage = read_string("coverage.txt")
    }
}

task createINI {
    input {
        String project
        String study
        String donor
        String reportId
        String assay
        String tumorId
        String normalId
        String patientStudyId
        String meanCoverage
        String attributes
        String modules = "djerbareporter/1.0.0 pandas/2.1.3"
        Int timeout = 4
        Int jobMemory = 2

        # WGTS-only (all-optional)
        String purpleZip = ""
        String msiFile = ""
        String ctdnaFile = ""
        String hrdPath = ""
        String mafPath = ""
        String mavisPath = ""
        String arribaPath = ""
        String rsemGenesResults = ""
        String callability = ""

        # TAR-only (all-optional)
        String cbioId = ""
        String ichorcnaFile = ""
        String consensuscruncherFile = ""
        String consensuscruncherFileNormal = ""
        String mafFile = ""
        String mafFileNormal = ""
        String segFile = ""
        String plotsFile = ""
        String groupId = ""
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
        purpleZip: "Path to purple output"
        msiFile: "Path to msi output"
        ctdnaFile: "Path to SNP counts"
        hrdPath: "Path to genome signatures"
        patientStudyId: "Patient identifier"
        mafPath: "Path to mutect2 output"
        mavisPath: "Path to mavis output"
        arribaPath: "Path to gene fusion output"
        rsemGenesResults: "Path to rsem output"
        cbioId: "TAR Assay type"
        groupId: "External sample identifier"
        ichorcnaFile: "Path to ichorcna output"
        consensuscruncherFile: "Path to consensus cruncher output"
        consensuscruncherFileNormal: "Path to consensus cruncher output"
        mafFile: "Path to consensus cruncher output"
        mafFileNormal: "Path to consensus cruncher output"
        segFile: "Path to ichorcna output"
        plotsFile: "Path to ichorcna output"
        callability: "Callability value from queryCallability task"
        meanCoverage: "Mean coverage value from queryCoverage task"
        modules: "Name and version of module to be loaded"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
    }

    command <<<
        if [[ "~{assay}" == "WGTS" ]]; then
            createIni \
                "~{project}" \
                "~{study}" \
                "~{donor}" \
                "~{reportId}" \
                "~{assay}" \
                "~{tumorId}" \
                "~{normalId}" \
                "~{patientStudyId}" \
                "~{meanCoverage}" \
                "~{attributes}" \
                "~{purpleZip}" \
                "~{msiFile}" \
                "~{ctdnaFile}" \
                "~{hrdPath}" \
                "~{mafPath}" \
                "~{mavisPath}" \
                "~{arribaPath}" \
                "~{rsemGenesResults}" \
                "~{callability}"
        else
            createIni \
                "~{project}" \
                "~{study}" \
                "~{donor}" \
                "~{reportId}" \
                "~{assay}" \
                "~{tumorId}" \
                "~{normalId}" \
                "~{patientStudyId}" \
                "~{meanCoverage}" \
                "~{attributes}" \
                "~{cbioId}" \
                "~{ichorcnaFile}" \
                "~{consensuscruncherFile}" \
                "~{consensuscruncherFileNormal}" \
                "~{mafFile}" \
                "~{mafFileNormal}" \
                "~{segFile}" \
                "~{plotsFile}" \
                "~{groupId}"
        fi
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
        File iniFile
        File sampleInfo
        File provenanceSubset
        String modules = "djerba/1.11.1"
        Int timeout = 10
        Int jobMemory = 25
    }

    parameter_meta {
        Prefix: "Prefix for the output files"
        iniFile: "The INI input for Djerba"
        sampleInfo: "Intermediate file with sample information"
        provenanceSubset: "Intermediate empty file required to run Djerba"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
        modules: "Name and version of module to be loaded"
    }

    command <<<
        mkdir -p ~{Prefix}
        mv ~{sampleInfo} ~{Prefix}
        mv ~{provenanceSubset} ~{Prefix}

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