version 1.0

struct ReportInputFiles {
    File purpleZip
    File msiFile
    File ctdnaFile
    File hrdPath
    File mafPath
    File mavisPath
    File arribaPath
    File rsemGenesResults
}

workflow djerbaReportGenerator {
    input {
        String project
        String study
        String donor
        String reportId
        String assay
        String tumorId
        String normalId
        String sampleNameTumor
        String sampleNameNormal
        String sampleNameAux
        ReportInputFiles reportFiles
        String patientStudyId
        Array[String] LimsId
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
        sampleNameTumor: "Sample name for the tumour WG sample"
        sampleNameNormal: "Sample name for the normal WG sample"
        sampleNameAux: "Sample name for tumor transcriptome (WT)"
        reportFiles: "Struct containing paths to input files required for Djerba report generation"
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
                name : "pandas/2.1.3",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/60_pandas.yaml?ref_type=heads"
            },
            {
                name : "gsi-qc-etl/1.36",
                url: "https://gitlab.oicr.on.ca/ResearchIT/modulator/-/blob/master/code/gsi/80_gsiqcetl.yaml?ref_type=heads"
            },
            {
                name : "djerba/1.9.2",
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

    call queryCallability {
        input:
            LimsId = LimsId,
            pythonScript = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/DjerbaReportGenerator/scripts/callSearch.py",
            activeCache = "/scratch2/groups/gsi/production/qcetl_v1",
            archivalCache = "/scratch2/groups/gsi/production/qcetl_archival"
    }

    call queryCoverage {
        input:
            LimsId = LimsId,
            pythonScript = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/DjerbaReportGenerator/scripts/covSearch.py",
            activeCache = "/scratch2/groups/gsi/production/qcetl_v1",
            archivalCache = "/scratch2/groups/gsi/production/qcetl_archival"
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
            purpleZip = reportFiles.purpleZip,
            msiFile = reportFiles.msiFile,
            ctdnaFile = reportFiles.ctdnaFile,
            hrdPath = reportFiles.hrdPath,
            patientStudyId = patientStudyId,
            mafPath = reportFiles.mafPath,
            mavisPath = reportFiles.mavisPath,
            arribaPath = reportFiles.arribaPath,
            rsemGenesResults = reportFiles.rsemGenesResults,
            callability = queryCallability.callability,
            meanCoverage = queryCoverage.meanCoverage,
            pythonScript = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/DjerbaReportGenerator/scripts/createIni.py"
    }

    call createIntermediaries {
        input:
            project = project,
            donor = donor,
            patientStudyId = patientStudyId,
            tumorId = tumorId,
            normalId = normalId,
            sampleNameTumor = sampleNameTumor,
            sampleNameNormal = sampleNameNormal,
            sampleNameAux = sampleNameAux
    }

    call runDjerba {
        input:
            Prefix = outputFileNamePrefix,
            iniFile = createINI.iniFile,
            sampleInfo = createIntermediaries.sampleInfo,
            provenanceSubset = createIntermediaries.provenanceSubset
    }

    output {
        File reportHTML = runDjerba.reportHtml
        File reportPDF = runDjerba.reportPdf
        File reportJSON = runDjerba.reportJson
    }
}

# ========================
# Configure and run djerba
# ========================

task queryCallability {
    input {
        Array[String] LimsId
        String pythonScript 
        String activeCache
        String archivalCache
        String modules = "gsi-qc-etl/1.36"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        LimsId: "The LIMS Identifiers that will be used to query the cache"
        pythonScript: "Path to the Python script that queries the SQLite database"
        activeCache: "Path to the qc etl cache for active projects"
        archivalCache: "Path to the qc etl cache for all active and inactive projects"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        LimsId="~{sep=" " LimsId}"
        python3 ~{pythonScript} --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache}
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
        String pythonScript 
        String activeCache
        String archivalCache
        String modules = "gsi-qc-etl/1.36"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        LimsId: "The LIMS Identifiers that will be used to query the cache"
        pythonScript: "Path to the Python script that queries the SQLite database"
        activeCache: "Path to the qc etl cache for active projects"
        archivalCache: "Path to the qc etl cache for all active and inactive projects"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        LimsId="~{sep=" " LimsId}"
        python3 ~{pythonScript} --lims-id $LimsId --gsiqcetl-dir ~{activeCache} --gsiqcetl-dir ~{archivalCache}
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
        String purpleZip
        String msiFile
        String ctdnaFile
        String hrdPath
        String patientStudyId
        String mafPath
        String mavisPath
        String arribaPath
        String rsemGenesResults
        String callability
        String meanCoverage
        String pythonScript
        String modules = "pandas/2.1.3"
        Int timeout = 4
        Int jobMemory = 2
    }

    parameter_meta {
        project: "Project name"
        study: "Study"
        donor: "Donor"
        reportId: "Report identifier"
        assay: "Assay name"
        tumorId: "Tumor sample identifier"
        normalId: "Matched normal sample identifier"
        purpleZip: "Path to purple output"
        msiFile: "Path to msi output"
        ctdnaFile: "Path to SNP counts"
        hrdPath: "Path to genome signatures"
        patientStudyId: "Patient identifier"
        mafPath: "Path to mutect2 output"
        mavisPath: "Path to mavis output"
        arribaPath: "Path to gene fusion output"
        rsemGenesResults: "Path to rsem output"
        callability: "Callability value from queryCallability task"
        meanCoverage: "Mean coverage value from queryCoverage task"
        pythonScript: "Path to the Python script that creates the INI file"
        modules: "Name and version of module to be loaded"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
    }

    command <<<
        python3 ~{pythonScript} \
        ~{project} \
        ~{study} \
        ~{donor} \
        ~{reportId} \
        ~{assay} \
        ~{tumorId} \
        ~{normalId} \
        ~{purpleZip} \
        ~{msiFile} \
        ~{ctdnaFile} \
        ~{hrdPath} \
        ~{patientStudyId} \
        ~{mafPath} \
        ~{mavisPath} \
        ~{arribaPath} \
        ~{rsemGenesResults} \
        ~{callability} \
        ~{meanCoverage}
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
        String modules = "djerba/1.9.2"
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
        File reportHtml = "~{Prefix}/~{Prefix}-v1_report.research.html"
        File reportPdf = "~{Prefix}/~{Prefix}-v1_report.research.pdf"
        File reportJson = "~{Prefix}/~{Prefix}-v1_report.json"
    }
}
