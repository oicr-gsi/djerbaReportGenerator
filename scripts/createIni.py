import argparse
import configparser
import os
import sys

def createINI(args):
    config = configparser.ConfigParser(allow_no_value=True)
    assay = args.assay.upper()

    if assay == "WGTS":
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
    elif assay == "TAR":
        sections = [
            "core",
            "tar_input_params_helper",
            "report_title",
            "patient_info",
            "case_overview",
            "treatment_options_merger",
            "tar.status",
            "summary",
            "tar.sample",
            "tar.snv_indel",
            "tar.swgs", 
            "gene_information_merger",       
            "supplement.body",
        ]
    else:
        print(f"Unsupported assay type: {assay}")
        sys.exit(1)

    for section in sections:
        config.add_section(section)

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

        elif section == "tar_input_params_helper":
            config[section] = {
                "assay": args.assay,
                "cbio_id": args.cbioId,
                "donor": args.donor,
                "known_variants": "Required",
                "normal_id": args.normal_id,
                "oncotree_code": "N/A",
                "patient_study_id": args.patient_study_id,
                "primary_cancer": "None",
                "project": args.project,
                "requisition_approved": "2025-01-01",
                "requisition_id": args.report_id,
                "sample_type": "Required",
                "site_of_biopsy": "Required",
                "study": args.study,
                "tumour_id": args.tumor_id,
                "attributes": args.attributes,
            }

        elif section == "wgts.cnv_purple":
            config[section] = {
                "attributes": args.attributes,
                "assay": args.assay,
                "tumour_id": args.tumor_id,
                "oncotree_code": "NA",
                "whizbam_project": args.project,
                "purple_zip": args.purple_zip
            }

        elif section == "core":
            config[section] = {
                "author": "Analysis Author",
                "report_id": args.report_id,
                "report_version": "1.0",
            }

        elif section == "genomic_landscape":
            config[section] = {
                "attributes": args.attributes,
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
                "attributes": args.attributes,
                "assay": args.assay,
                "primary_cancer": "None",
                "site_of_biopsy": "Required",
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
                "attributes": args.attributes,
                "callability": args.callability,
                "mean_coverage": f"{args.mean_coverage}x",
                "oncotree_code": "NA",
                "sample_type": "NA",
                "donor": args.donor,
                "tumour_id": args.tumor_id
            }

        elif section == "wgts.snv_indel":
            config[section] = {
                "attributes": args.attributes,
                "maf_path": args.maf_path,
                "oncotree_code": "NA",
                "tumour_id": args.tumor_id,
                "normal_id": args.normal_id,
                "project": args.project,
                "whizbam_project": args.project
            }

        elif section == "fusion":
            config[section] = {
                "attributes": args.attributes,
                "project": args.project,
                "mavis_path": args.mavis_path,
                "arriba_path": args.arriba_path,
                "tumour_id": args.tumor_id,
                "oncotree_code": "NA",
                "whizbam_project": args.project
            }

        elif section == "expression_helper":
            config[section] = {
                "attributes": args.attributes,
                "rsem_genes_results": args.rsem_genes_results,
                "tumour_id": args.tumor_id,
                "depends_configure": "case_overview"
            }

        elif section == "supplement.body":
            config[section] = {
                "attributes": args.attributes,
                "assay": args.assay,
                "report_signoff_date": "yyyy-mm-dd",
                "user_supplied_draft_date": "2025-04-28",
                "clinical_geneticist_name": "PLACEHOLDER",
                "clinical_geneticist_licence": "XXXXXXX",
                "failed": "False",
                "template_dir": "/.mounts/labs/gsi/modulator/sw/Ubuntu20.04/djerba-1.9.2/lib/python3.10/site-packages/djerba/plugins/supplement/body"
            }

        elif section == "gene_information_merger":
            config[section] = {"attributes": args.attributes}

        elif section == "report_title":
            config[section] = {"attributes": args.attributes}

        elif section == "patient_info":
            config[section] = {"attributes": args.attributes}

        elif section == "treatment_options_merger":
            config[section] = {"attributes": f"{args.attributes},supplementary"}

        elif section == "tar.status":
            config[section] = {"attributes": args.attributes}

        elif section == "summary":
            config[section] = {"attributes": args.attributes}

        elif section == "tar.sample":
            config[section] = {
                "attributes": args.attributes,
                "group_id": args.group_id,
                "oncotree_code": "N/A",
                "known_variants": "Required",
                "sample_type": "Required",
                "ichorcna_file": args.ichorcna_file,
                "consensus_cruncher_file": args.consensuscruncher_file,
                "consensus_cruncher_file_normal": args.consensuscruncher_file_normal,
                "raw_coverage": args.mean_coverage
            }

        elif section == "tar.snv_indel":
            config[section] = {
                "attributes": args.attributes,
                "donor": args.donor,
                "oncotree_code": "N/A",
                "assay": args.assay,
                "cbio_id": args.cbioId,
                "tumour_id": args.tumor_id,
                "normal_id": args.normal_id,
                "maf_file": args.maf_file,
                "maf_file_normal": args.maf_file_normal,
            }

        elif section == "tar.swgs":
            config[section] = {
                "attributes": args.attributes,
                "donor": args.donor,
                "oncotree_code": "N/A",
                "tumour_id": args.tumor_id,
                "seg_file": args.seg_file,
                "plots_file": args.plots_file,
                "clinical": "True" if args.attributes == "clinical" else "False",
                "supplementary": "False"
            }

    return config


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Djerba report config using positional arguments.")

    # Common
    parser.add_argument("project")
    parser.add_argument("study")
    parser.add_argument("donor")
    parser.add_argument("report_id")
    parser.add_argument("assay")
    parser.add_argument("tumor_id")
    parser.add_argument("normal_id")
    parser.add_argument("patient_study_id")
    parser.add_argument("mean_coverage")
    parser.add_argument("--attributes", default="research")

    # WGTS-specific
    parser.add_argument("--purple_zip")
    parser.add_argument("--msi_file")
    parser.add_argument("--ctdna_file")
    parser.add_argument("--hrd_path")
    parser.add_argument("--maf_path")
    parser.add_argument("--mavis_path")
    parser.add_argument("--arriba_path")
    parser.add_argument("--rsem_genes_results")
    parser.add_argument("--callability")

    # TAR-specific
    parser.add_argument("--cbioId")
    parser.add_argument("--ichorcna_file")
    parser.add_argument("--consensuscruncher_file")
    parser.add_argument("--consensuscruncher_file_normal")
    parser.add_argument("--maf_file")
    parser.add_argument("--maf_file_normal")
    parser.add_argument("--seg_file")
    parser.add_argument("--plots_file")
    parser.add_argument("--group_id")

    args = parser.parse_args()
    config = createINI(args)

    with open("djerba_input.ini", "w") as configfile:
        config.write(configfile)

    print("INI file successfully written as 'djerba_input.ini'")
