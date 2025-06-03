import argparse
import configparser
import os

def createINI(args):
    config = configparser.ConfigParser(allow_no_value=True)

    # Define all sections of INI file
    # The order of sections is important for the final output
    sections = [
        "input_params_helper",
        "wgts.cnv_purple",
        "core",
        "genomic_landscape",
        "case_overview",
        "sample",
        "wgts.snv_indel",
        "fusion",
        "expression_helper",
        "supplement.body",
        "gene_information_merger"
    ]

    # Add all sections first
    for section in sections:
        config.add_section(section)

    # Conditionally populate each section
    for section in sections:
        if section == "input_params_helper":
            config[section] = {
                "assay": args.assay,
                "donor": args.donor,
                "oncotree_code": "NA",
                "primary_cancer": "NA",
                "project": args.project,
                "requisition_approved": "2025-01-01",
                "requisition_id": args.report_id,
                "sample_type": "NA",
                "site_of_biopsy": "NA",
                "study": args.study
            }

        elif section == "wgts.cnv_purple":
            config[section] = {
                "attributes": "research",
                "assay": args.assay,
                "tumour_id": args.tumor_id,
                "oncotree_code": "NA",
                "whizbam_project": args.project,
                "purple_zip": args.purple_zip
            }

        elif section == "core":
            config[section] = {
                "author": "Analysis Author"
            }

        elif section == "genomic_landscape":
            config[section] = {
                "attributes": "research",
                "tumour_id": args.tumor_id,
                "oncotree_code": "NA",
                "msi_file": args.msi_file,
                "ctdna_file": args.ctdna_file,
                "hrd_path": args.hrd_path,
                "sample_type": "NA",
                "clinical": "False",
                "supplementary": "False"
            }

        elif section == "case_overview":
            config[section] = {
                "attributes": "research",
                "assay": args.assay,
                "primary_cancer": "NA",
                "site_of_biopsy": "NA",
                "donor": args.donor,
                "study": args.study,
                "patient_study_id": args.patient_study_id,
                "tumour_id": args.tumor_id,
                "normal_id": args.normal_id,
                "report_id": args.report_id,
                "requisition_approved": "2025-01-01"
            }

        elif section == "sample":
            config[section] = {
                "attributes": "research",
                "callability": args.callability,
                "mean_coverage": args.mean_coverage,
                "oncotree_code": "NA",
                "sample_type": "NA",
                "donor": args.donor,
                "tumour_id": args.tumor_id
            }

        elif section == "wgts.snv_indel":
            config[section] = {
                "attributes": "research",
                "maf_path": args.maf_path,
                "oncotree_code": "NA",
                "tumour_id": args.tumor_id,
                "normal_id": args.normal_id,
                "project": args.project,
                "whizbam_project": args.project
            }

        elif section == "fusion":
            config[section] = {
                "attributes": "research",
                "project": args.project,
                "mavis_path": args.mavis_path,
                "arriba_path": args.arriba_path,
                "tumour_id": args.tumor_id,
                "oncotree_code": "NA",
                "whizbam_project": args.project
            }

        elif section == "expression_helper":
            config[section] = {
                "attributes": "research",
                "rsem_genes_results": args.rsem_genes_results,
                "tumour_id": args.tumor_id,
                "depends_configure": "case_overview"
            }

        elif section == "supplement.body":
            config[section] = {
                "attributes": "research",
                "assay": args.assay,
                "report_signoff_date": "yyyy-mm-dd",
                "user_supplied_draft_date": "2025-04-28",
                "clinical_geneticist_name": "PLACEHOLDER",
                "clinical_geneticist_licence": "XXXXXXX",
                "failed": "False",
                "template_dir": "/.mounts/labs/gsi/modulator/sw/Ubuntu20.04/djerba-1.9.2/lib/python3.10/site-packages/djerba/plugins/supplement/body"
            }

        elif section == "gene_information_merger":
            config[section] = {
                "attributes": "research"
            }

    return config


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Djerba report config using positional arguments.")

    parser.add_argument("project")
    parser.add_argument("study")
    parser.add_argument("donor")
    parser.add_argument("report_id")
    parser.add_argument("assay")
    parser.add_argument("tumor_id")
    parser.add_argument("normal_id")
    parser.add_argument("purple_zip")
    parser.add_argument("msi_file")
    parser.add_argument("ctdna_file")
    parser.add_argument("hrd_path")
    parser.add_argument("patient_study_id")
    parser.add_argument("maf_path")
    parser.add_argument("mavis_path")
    parser.add_argument("arriba_path")
    parser.add_argument("rsem_genes_results")
    parser.add_argument("callability")
    parser.add_argument("mean_coverage")

    args = parser.parse_args()
    config = createINI(args)

    output_file = "djerba_input.ini"
    if not os.path.exists(output_file):
        open(output_file, "w").close()

    with open(output_file, "w") as configfile:
        config.write(configfile)

    print(f"INI file successfully written as '{output_file}'")
