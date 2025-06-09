version 1.0

struct ReportInputFiles {
    File purple_zip
    File msi_file
    File ctdna_file
    File hrd_path
    File maf_path
    File mavis_path
    File arriba_path
    File rsem_genes_results
}

workflow DjerbaReportGenerator {
    input {
        String project
        String study
        String donor
        String report_id
        String assay
        String tumor_id
        String normal_id
        String sample_name_tumor
        String sample_name_normal
        String sample_name_aux
        ReportInputFiles report_files
        String patient_study_id
        Array[String] LIMS_ID
        String outputFileNamePrefix = donor  
    }

    parameter_meta {
        project: "Project name"
        study: "Study"
        donor: "Donor"
        report_id: "Report identifier"
        assay: "Assay name"
        tumor_id: "Tumor sample identifier"
        normal_id: "Matched normal sample identifier"
        sample_name_tumor: "Sample name for the tumour WG sample"
        sample_name_normal: "Sample name for the normal WG sample"
        sample_name_aux: "Sample name for tumor transcriptome (WT)"
        report_files: "Struct containing paths to input files required for Djerba report generation"
        patient_study_id: "Patient identifier"
        LIMS_ID: "Array of LIMS IDs"
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
            LIMS_ID = LIMS_ID,
            python_script = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/DjerbaReportGenerator/scripts/callSearch.py",
            active_cache = "/scratch2/groups/gsi/production/qcetl_v1",
            archival_cache = "/scratch2/groups/gsi/production/qcetl_archival"
    }

    call queryCoverage {
        input:
            LIMS_ID = LIMS_ID,
            python_script = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/DjerbaReportGenerator/scripts/covSearch.py",
            active_cache = "/scratch2/groups/gsi/production/qcetl_v1",
            archival_cache = "/scratch2/groups/gsi/production/qcetl_archival"
    }

    call createINI {
        input:
            project = project,
            donor = donor,
            study = study,
            report_id = report_id,
            assay = assay,
            tumor_id = tumor_id,
            normal_id = normal_id,
            purple_zip = report_files.purple_zip,
            msi_file = report_files.msi_file,
            ctdna_file = report_files.ctdna_file,
            hrd_path = report_files.hrd_path,
            patient_study_id = patient_study_id,
            maf_path = report_files.maf_path,
            mavis_path = report_files.mavis_path,
            arriba_path = report_files.arriba_path,
            rsem_genes_results = report_files.rsem_genes_results,
            callability = queryCallability.callability,
            mean_coverage = queryCoverage.mean_coverage,
            python_script = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/DjerbaReportGenerator/scripts/createIni.py"
    }

    call createIntermediaries {
        input:
            project = project,
            donor = donor,
            patient_study_id = patient_study_id,
            tumor_id = tumor_id,
            normal_id = normal_id,
            sample_name_tumor = sample_name_tumor,
            sample_name_normal = sample_name_normal,
            sample_name_aux = sample_name_aux
    }

    call runDjerba {
        input:
            Prefix = outputFileNamePrefix,
            ini_file = createINI.ini_file,
            sample_info = createIntermediaries.sample_info,
            provenance_subset = createIntermediaries.provenance_subset
    }

    output {
        File reportHTML = runDjerba.report_html
        File reportPDF = runDjerba.report_pdf
        File reportJSON = runDjerba.report_json
    }
}

# ========================
# Configure and run djerba
# ========================

task queryCallability {
    input {
        Array[String] LIMS_ID
        String python_script 
        String active_cache
        String archival_cache
        String modules = "gsi-qc-etl/1.36"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        LIMS_ID: "The LIMS Identifiers that will be used to query the cache"
        python_script: "Path to the Python script that queries the SQLite database"
        active_cache: "Path to the qc etl cache for active projects"
        archival_cache: "Path to the qc etl cache for all active and inactive projects"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        LIMS_IDS="~{sep=" " LIMS_ID}"
        python3 ~{python_script} --lims-id $LIMS_IDS --gsiqcetl-dir ~{active_cache} --gsiqcetl-dir ~{archival_cache}
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
        Array[String] LIMS_ID
        String python_script 
        String active_cache
        String archival_cache
        String modules = "gsi-qc-etl/1.36"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        LIMS_ID: "The LIMS Identifiers that will be used to query the cache"
        python_script: "Path to the Python script that queries the SQLite database"
        active_cache: "Path to the qc etl cache for active projects"
        archival_cache: "Path to the qc etl cache for all active and inactive projects"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        LIMS_IDS="~{sep=" " LIMS_ID}"
        python3 ~{python_script} --lims-id $LIMS_IDS --gsiqcetl-dir ~{active_cache} --gsiqcetl-dir ~{archival_cache}
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        String mean_coverage = read_string("coverage.txt")
    }
}

task createINI {
    input {
        String project
        String study
        String donor
        String report_id
        String assay
        String tumor_id
        String normal_id
        String purple_zip
        String msi_file
        String ctdna_file
        String hrd_path
        String patient_study_id
        String maf_path
        String mavis_path
        String arriba_path
        String rsem_genes_results
        String callability
        String mean_coverage
        String python_script
        String modules = "pandas/2.1.3"
        Int timeout = 4
        Int jobMemory = 2
    }

    parameter_meta {
        project: "Project name"
        study: "Study"
        donor: "Donor"
        report_id: "Report identifier"
        assay: "Assay name"
        tumor_id: "Tumor sample identifier"
        normal_id: "Matched normal sample identifier"
        purple_zip: "Path to purple output"
        msi_file: "Path to msi output"
        ctdna_file: "Path to SNP counts"
        hrd_path: "Path to genome signatures"
        patient_study_id: "Patient identifier"
        maf_path: "Path to mutect2 output"
        mavis_path: "Path to mavis output"
        arriba_path: "Path to gene fusion output"
        rsem_genes_results: "Path to rsem output"
        callability: "Callability value from queryCallability task"
        mean_coverage: "Mean coverage value from queryCoverage task"
        python_script: "Path to the Python script that creates the INI file"
        modules: "Name and version of module to be loaded"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
    }

    command <<<
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
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        File ini_file = "djerba_input.ini"
    }
}

task createIntermediaries {
    input {
        String project
        String donor
        String patient_study_id
        String tumor_id
        String normal_id
        String sample_name_tumor
        String sample_name_normal
        String sample_name_aux
    }

    parameter_meta {
        project: "Project name"
        donor: "Donor"
        patient_study_id: "Patient identifier"
        tumor_id: "Tumor sample identifier"
        normal_id: "Matched normal sample identifier"
        sample_name_tumor: "Sample name for the tumor WG sample"
        sample_name_normal: "Sample name for the normal WG sample"
        sample_name_aux: "Sample name for tumor transcriptome (WT)"
    }

    command <<<
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
    >>>

    output {
        File sample_info = "sample_info.json"
        File provenance_subset = "provenance_subset.tsv.gz"
    }
}

task runDjerba {
    input {
        String Prefix
        File ini_file
        File sample_info
        File provenance_subset
        String modules = "djerba/1.9.2"
        Int timeout = 10
        Int jobMemory = 25
    }

    parameter_meta {
        Prefix: "Prefix for the output files"
        ini_file: "The INI input for Djerba"
        sample_info: "Intermediate file with sample information"
        provenance_subset: "Intermediate empty file required to run Djerba"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
        modules: "Name and version of module to be loaded"
    }

    command <<<
        mkdir -p ~{Prefix}
        mv ~{sample_info} ~{Prefix}
        mv ~{provenance_subset} ~{Prefix}

        $DJERBA_ROOT/bin/djerba.py report \
            -i ~{ini_file} \
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
        File report_html = "~{Prefix}/~{Prefix}-v1_report.research.html"
        File report_pdf = "~{Prefix}/~{Prefix}-v1_report.research.pdf"
        File report_json = "~{Prefix}/~{Prefix}-v1_report.json"
    }
}
