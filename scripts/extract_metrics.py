import os
import argparse 
import pandas as pd
import json

def process_json(data):
    json_dict = {}
    study_title = data['Study Title'].iloc[0]
    if data['Study Title'].nunique() == 1:
        json_dict['ClinicalReportGeneration.project'] = study_title
        json_dict['ClinicalReportGeneration.study'] = study_title

    root_sample_name = data['Root Sample Name'].iloc[0]
    if data['Root Sample Name'].nunique() == 1:
        json_dict['ClinicalReportGeneration.donor'] = root_sample_name
        json_dict['ClinicalReportGeneration.report_id'] = root_sample_name
    
    sample_names = []
    for _, row in data.iterrows():
        if row['Library Type'] == 'WG' and row['Tissue Type'] == 'P':
            sample_names.append(f"ClinicalReportGeneration.sample_name_tumor: {row['Sample Name']}")
        elif row['Library Type'] == 'WG' and row['Tissue Type'] == 'R':
            sample_names.append(f"ClinicalReportGeneration.sample_name_normal: {row['Sample Name']}")
        elif row['Library Type'] == 'WT' and row['Tissue Type'] == 'P':
            sample_names.append(f"ClinicalReportGeneration.sample_name_aux: {row['Sample Name']}")

    for name in sample_names:
        key, value = name.split(': ')
        json_dict[key] = value

    lims = data[~(
        (data['Sequencer Run Platform Name'] == 'Illumina_MiSeq') |
        (data['Tissue Type'] == 'R') |
        (data['Library Type'] == 'WT')
    )]

    lims_ids = lims['LIMS ID'].unique().tolist()
    lims_ids.sort()
    print(lims_ids)
    json_dict['ClinicalReportGeneration.LIMS_ID'] = lims_ids

    return json_dict

def query_fpr(fp_path, donor):
    df_out = []
    chunk_size = 10000
    for chunk in pd.read_csv(fp_path, sep='\t', compression='gzip', chunksize = chunk_size):
        filt_chunk = chunk[chunk.iloc[:, 7] == donor]
        col = filt_chunk.iloc[:, [1,7,13,17,22,56]]
        df_out.append(col)
    
    df = pd.concat(df_out, ignore_index=True)
    df['Library Type'] = df['Sample Attributes'].str.extract(r'geo_library_source_template_type=([^;]+)')
    df['Tissue Type'] = df['Sample Attributes'].str.extract(r'geo_tissue_type=([^;]+)')
    
    df = df.drop('Sample Attributes', axis=1)
    df.drop_duplicates(inplace=True)
    
    return df 

if __name__ == "__main__":
    # create a parser for command line arguments 
    parser = argparse.ArgumentParser(
        description='Extract metrics from FPR and generate an input json file for ClinicalReportGenerator.wdl '
    )
    parser.add_argument(
        'donor',
        type=str,
        help='Donor ID that would be used for querying File Provenance'
    )
    args = parser.parse_args()

    fp_path = "/scratch2/groups/gsi/production/vidarr/vidarr_files_report_latest.tsv.gz"
    metrics = query_fpr(fp_path, args.donor)
    json_dict = process_json(metrics)

    output_file = f'{args.donor}.json'
    with open(output_file, 'w') as json_file:
        json.dump(json_dict, json_file, indent=4)