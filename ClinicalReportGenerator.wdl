version 1.0

workflow ClinicalReportGeneration {
    input {
        File InputIni
        String finalOutputDirectory = "" 
        String outputFileNamePrefix = sub(basename(InputIni), ".ini", "")  
    }

    parameter_meta {
        InputIni: "An input INI configuration file for djerba to generate clinical reports."
        finalOutputDirectory: "The output directory where djerba will store its results"
        outputFileNamePrefix: "Output prefix, customizable."
    }

    call runDjerba {
        input:
            Input = InputIni,
            outputDir = finalOutputDirectory,
            Prefix = outputFileNamePrefix
    }

    meta {
        author: "Aditi Nagaraj Nallan"
        email: "anallan@oicr.on.ca"
        description: "Given an input INI file, djerba will be used to generate clinical report documents from pipeline data, with a modular structure based on plugins."
        dependencies: [
            {
                name : "djerba/1.8.2",
                url: "https://github.com/oicr-gsi/djerba"
            }
        ]
        output_meta: {
            reportHTML: {
                description: "The clinical report in HTML file format",
                vidarr_label: "reportHTML"
            },
            reportPDF: {
                description: "The clinical report in PDF file format",
                vidarr_label: "reportPDF"
            }
        }
    }

    output {
        File reportHTML = runDjerba.report_html
        File reportPDF = runDjerba.report_pdf
    }
}

# ========================
# Configure and run djerba
# ========================

task runDjerba {
    input {
        File Input
        String outputDir
        String Prefix
        String modules = "djerba/1.8.2"
        Int timeout = 10
        Int jobMemory = 25
    }

    parameter_meta {
        Input: "Input file for report generation"
        jobMemory: "Memory in Gb for this job"
        timeout: "Timeout in hours"
        modules: "Name and version of module to be loaded"
    }

    command <<<
        mkdir -p ~{outputDir}

        $DJERBA_ROOT/bin/djerba.py report \
            -i ~{Input} \
            -o ~{outputDir} \
            --pdf \
            --no-archive 
    >>>

    runtime {
        modules: "~{modules}"
        memory: "~{jobMemory} GB"
        timeout: "~{timeout}"
    }

    output {
        File report_html = "~{outputDir}/~{Prefix}_report.research.html"
        File report_pdf = "~{outputDir}/~{Prefix}_report.research.pdf"
    }
}