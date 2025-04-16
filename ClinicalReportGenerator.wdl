version 1.0

workflow ClinicalReportGeneration {
    input {
        String project
        String study
        String donor
        String report_id
        String sample_name_tumor
        String sample_name_normal
        String sample_name_aux
        Array[String] LIMS_ID
        String outputFileNamePrefix = donor  
    }

    parameter_meta {
        project: "Project name"
        study: "Study Name"
        donor: "Donor"
        report_id: "Report identifier"
        sample_name_tumor: "Sample name for the tumour WG sample"
        sample_name_normal: "Sample name for the normal WG sample"
        sample_name_aux: "Sample name for tumor transcriptome (WT)"
        LIMS_ID: "Array of LIMS IDs"
        outputFileNamePrefix: "Output prefix, customizable based on donor"
    }

    meta {
        author: "Aditi Nagaraj Nallan"
        email: "anallan@oicr.on.ca"
        description: "Given metrics from file provenance, the workflow will create an intermediate INI file and run djerba to generate RUO clinical reports, with a modular structure based on plugins."
        dependencies: [
            {
                name : "pandas/2.1.3",
                url: "https://github.com/oicr-gsi/djerba"
            },
            {
                name : "sqlite3/3.39.3",
                url: "https://github.com/oicr-gsi/djerba"
            },
            {
                name : "djerba/1.8.4",
                url: "https://github.com/oicr-gsi/djerba"
            }
        ]
        output_meta: {
            reportHTML: {
                description: "The RUO clinical report in HTML file format",
                vidarr_label: "reportHTML"
            },
            reportPDF: {
                description: "The RUO clinical report in PDF file format",
                vidarr_label: "reportPDF"
            }
        }
    }

    call queryCallability {
        input:
            LIMS_ID = LIMS_ID,
            python_script = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/ClinicalReportGenerator/scripts/callSearch.py"
    }

    call queryCoverage {
        input:
            LIMS_ID = LIMS_ID,
            python_script = "/.mounts/labs/gsiprojects/gsi/gsiusers/anallan/repositories/ClinicalReportGenerator/scripts/covSearch.py"
    }

    call createINI {
        input:
            donor = donor,
            project = project,
            sample_name_tumor = sample_name_tumor,
            sample_name_normal = sample_name_normal,
            sample_name_aux = sample_name_aux,
            report_id = report_id,
            callability = queryCallability.callability,
            mean_coverage = queryCoverage.mean_coverage,
            study = study
    }

    call runDjerba {
        input:
            Prefix = outputFileNamePrefix,
            ini_file = createINI.ini_file
    }

    output {
        File reportHTML = runDjerba.report_html
        File reportPDF = runDjerba.report_pdf
    }
}

# ========================
# Configure and run djerba
# ========================

task queryCallability {
    input {
        Array[String] LIMS_ID
        String python_script 
        String modules = "pandas/2.1.3 sqlite3/3.39.3"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        LIMS_ID: "The LIMS Identifiers that will be used to query the cache"
        python_script: "Path to the Python script that queries the SQLite database"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        LIMS_IDS="~{sep=" " LIMS_ID}"
        python3 ~{python_script} $LIMS_IDS
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
        String modules = "pandas/2.1.3 sqlite3/3.39.3"
        Int timeout = 5
        Int jobMemory = 12
    }

    parameter_meta {
        LIMS_ID: "The LIMS Identifiers that will be used to query the cache"
        python_script: "Path to the Python script that queries the SQLite database"
        modules: "Name and version of module to be loaded"
        timeout: "Timeout in hours"
        jobMemory: "Memory in Gb for this job" 
    }

    command <<<
        LIMS_IDS="~{sep=" " LIMS_ID}"
        python3 ~{python_script} $LIMS_IDS
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
        String donor
        String project
        String sample_name_tumor
        String sample_name_normal
        String sample_name_aux
        String report_id
        String callability
        String mean_coverage
        String study
        Int timeout = 4
        Int jobMemory = 2
    }

    parameter_meta {
        donor: "Donor"
        project: "Project name"
        sample_name_tumor: "Sample name for the tumor WG sample"
        sample_name_normal: "Sample name for the normal WG sample"
        sample_name_aux: "Sample name for tumor transcriptome (WT)"
        report_id: "Report identifier"
        callability: "Callability value from queryCallability task"
        mean_coverage: "Mean coverage value from queryCoverage task"
        study: "Study"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
    }

    command <<<
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
    >>>

    runtime {
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        File ini_file = "temp_ini_file.ini"
    }
}

task runDjerba {
    input {
        String Prefix
        File ini_file
        String modules = "djerba/1.8.4"
        Int timeout = 10
        Int jobMemory = 25
    }

    parameter_meta {
        Prefix: "Prefix for the output files"
        ini_file: "The INI input for Djerba"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
        modules: "Name and version of module to be loaded"
    }

    command <<<
        mkdir -p ~{Prefix}

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
        File report_html = "~{Prefix}/~{Prefix}_report.research.html"
        File report_pdf = "~{Prefix}/~{Prefix}_report.research.pdf"
    }
}