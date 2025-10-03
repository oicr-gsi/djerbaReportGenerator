#! /usr/bin/env python3

import json, re, sys
from html import escape
from string import Template

class blurb_base:
    # base class with constants
    PLUGINS = 'plugins'
    RESULTS = 'results'
    BODY = 'body'
    BODY_TC = 'Body'

    @staticmethod
    def comma_separated_with_and(my_list):
        # convert my_list to a comma-separated string with 'and' before the last item
        if len(my_list) >= 2:
            last_item = my_list.pop()
            last_item = ' and '+last_item
        else:
            last_item = None
        list_string = ', '.join(my_list)
        if last_item:
            list_string = list_string + last_item
        return list_string

    @staticmethod
    def make_ordinal(n):
        '''
        Convert an integer into its ordinal representation::

            make_ordinal(0)   => '0th'
            make_ordinal(3)   => '3rd'
            make_ordinal(122) => '122nd'
            make_ordinal(213) => '213th'
        (copied from djerba.util.html)
        '''
        n = int(n)
        if 11 <= (n % 100) <= 13:
            suffix = 'th'
        else:
            suffix = ['th', 'st', 'nd', 'rd', 'th'][min(n % 10, 4)]
        return str(n) + suffix

    @staticmethod
    def number_to_words(n):
        ones = [
            "zero", "one", "two", "three", "four", "five", "six",
            "seven", "eight", "nine", "ten", "eleven", "twelve",
            "thirteen", "fourteen", "fifteen", "sixteen",
            "seventeen", "eighteen", "nineteen"
        ]
        tens = [
            "", "", "twenty", "thirty", "forty", "fifty",
            "sixty", "seventy", "eighty", "ninety"
        ]

        if n < 20:
            return ones[n]
        elif n < 100:
            return tens[n // 10] + ('' if n % 10 == 0 else '-' + ones[n % 10])
        elif n < 1000:
            return ones[n // 100] + " hundred" + ('' if n % 100 == 0 else ' and ' + number_to_words(n % 100))
        else:
            return str(n)


class cnv_blurb_maker(blurb_base):

    def __init__(self):
        pass

    def chromosome_sort_key(self, c):
        # find sort order for a chromosome name string
        # no prefix -- '4', not 'chr4'
        # unknown strings are ordered last
        chromosomes = [str(x) for x in range(1,23)]
        chromosomes.extend(['X', 'Y'])
        key = 25
        for i in range(len(chromosomes)):
            if c == chromosomes[i]:
                key = i
                break
        return key

    def get_input_body(self, report):
        # check data is available
        if 'cnv' in report[self.PLUGINS]:
            plugin = 'cnv'
        elif 'wgts.cnv_purple' in report[self.PLUGINS]:
            plugin = 'wgts.cnv_purple'
        else:
            print("No CNV data found", file=sys.stderr)
            sys.exit(1)
        body = report[self.PLUGINS][plugin][self.RESULTS][self.BODY]
        return body

    def order_body_items(self, body):
        # order by alteration, then chromosome
        ordered = {}
        for cnv in body:
            gene = cnv["Gene"]
            chromosome_arm = cnv["Chromosome"]
            chromosome = re.split('[pq]', chromosome_arm).pop(0)
            alteration = cnv["Alteration"]
            if alteration in ordered:
                if chromosome in ordered[alteration]:
                    ordered[alteration][chromosome].append(gene)
                else:
                    ordered[alteration][chromosome] = [gene,]
            else:
                ordered[alteration] = {}
                ordered[alteration][chromosome] = [gene,]
        return ordered


    def get_cnv_output(self, ordered):
        alteration_results = []
        for i, alteration in enumerate(ordered):
            gene_count = 0
            chromosome_results = []
            chromosomes = sorted(list(ordered[alteration].keys()), key=self.chromosome_sort_key)

            for chromosome in chromosomes:
                genes = ['_' + gene + '_' for gene in sorted(ordered[alteration][chromosome])]
                gene_count += len(genes)
                gene_string = self.comma_separated_with_and(genes)
                chromosome_string = f"{chromosome} ({gene_string})"
                chromosome_results.append(chromosome_string)

            chr_word = 'chromosome' if len(chromosomes) == 1 else 'chromosomes'
            alteration_string = self.comma_separated_with_and(chromosome_results)

            gene_word = "gene" if gene_count == 1 else "genes"
            alt_lower = alteration.lower()

            if gene_count == 1:
                article = "an" if alt_lower[0] in "aeiou" else "a"
                alt_phrase = f"{article} {alt_lower}"
            else:
                alt_phrase = f"{alt_lower}s"

            text = f"{self.number_to_words(gene_count)} {gene_word} subject to {alt_phrase} on {chr_word} {alteration_string}."

            if i == 0:
                text = "Copy number analysis uncovered " + text
            else:
                text = "In addition, " + text

            alteration_results.append(text)

        return " ".join(alteration_results) + ". " if alteration_results else ''

    def run(self, report):
        return self.get_cnv_output(self.order_body_items(self.get_input_body(report)))

class conclusion_maker(blurb_base):
    # make the conclusion of the blurb with values filled in from JSON

    TEMPLATE = "The tumor mutational burden was ${tmb} coding mutations per Mb, "+\
        "which corresponds to the ${percentile} percentile of "+\
        "${cohort} cohort ([${cohort_link_name}](${cohort_url})). "

    COHORT_NAMES = {
        "TCGA OV": "The Cancer Genome Atlas ovarian",
        "TCGA LIHC": "The Cancer Genome Atlas hepatocellular carcinoma (LIHC)",
        "TCGA BRCA": "The Cancer Genome Atlas BRCA",
        "TCGA CHOL": "The Cancer Genome Atlas CHOL"
    }

    LINK_DEFAULT = ('TCGA Pan-Cancer Atlas', 'https://gdc.cancer.gov/about-data/publications/pancanatlas')
    COHORT_LINKS = {
        "COMPASS": ('NCT02750657', 'https://clinicaltrials.gov/ct2/show/NCT02750657')
    }

    def run(self, report):
        gl = 'genomic_landscape'
        gl_info = report[self.PLUGINS][gl][self.RESULTS]['genomic_landscape_info']
        tmb = gl_info['TMB per megabase']
        percentile = gl_info['Cancer-specific Percentile']
        cohort = gl_info['Cancer-specific Cohort']
        if cohort == 'NA':
            # no cancer-specific data, fall back to pan-cancer results
            percentile = gl_info['Pan-cancer Percentile']
            cohort_text = 'the pan-cancer'
        elif cohort in self.COHORT_NAMES:
            cohort_text = self.COHORT_NAMES[cohort]
        elif cohort.startswith("TCGA"):
            # Always spell out TCGA in the cohort name
            suffix = cohort.replace("TCGA", "").strip()
            cohort_text = f"The Cancer Genome Atlas {suffix}"
        else:
            cohort_text = 'the '+cohort
        if cohort in self.COHORT_LINKS:
            [cohort_link_name, cohort_url] = self.COHORT_LINKS[cohort]
        else:
            [cohort_link_name, cohort_url] = self.LINK_DEFAULT
        values = {
            'tmb': tmb,
            'percentile': self.make_ordinal(percentile),
            'cohort': cohort_text,
            'cohort_link_name': cohort_link_name,
            'cohort_url': cohort_url
        }
        conclusion = Template(self.TEMPLATE).substitute(values)
        return conclusion

class fusion_blurb_maker(blurb_base):

    TEMPLATE = 'Fusion analysis uncovered ${total} clinically relevant '+\
        '${event_string}: ${variant_list}. '

    def make_variant_list(self, report):
        body = report[self.PLUGINS]['fusion'][self.RESULTS][self.BODY]
        fusion_results = set()
        for gene_result in body:
            fusion = '_'+gene_result['fusion']+'_'
            effect = gene_result['mutation effect'].lower()
            frame = gene_result['frame'].lower()
            fusion_string = '{0} {1} fusion of {2}'.format(effect, frame, fusion)
            fusion_results.add(fusion_string)
        fusion_list = list(fusion_results)
        fusion_list_with_prefix = ['a ' + result for result in fusion_list]
        return fusion_list_with_prefix            
            
    def run(self, report):
        if 'fusion' in report[self.PLUGINS]:
            total = report[self.PLUGINS]['fusion'][self.RESULTS]['Clinically relevant variants']
            total_word = self.number_to_words(total)
            variant_list = self.make_variant_list(report)
            if total >= 2:
                event_string = 'events'
            else:
                event_string = 'event'
            if len(variant_list) > 0:
                values = {
                    'event_string': event_string,
                    'total': total_word,
                    'variant_list': self.comma_separated_with_and(variant_list)
                }
                fusion_text = Template(self.TEMPLATE).substitute(values)
            else:
                fusion_text = ''
        else:
            # WGS report; no fusion plugin
            fusion_text = ''
        return fusion_text


class hrd_blurb_maker(blurb_base):
    # make a blurb section for HRD status, if present
    # TODO capture probability range in the plugin outputs, to produce uncertainty text if needed

    TEXT = "Genome-wide scoring of mutation and structural signatures " + \
           "detected homologous repair deficiency (HRD positive). "

    def run(self, report):
        gl = 'genomic_landscape'
        hrd_results = report[self.PLUGINS][gl][self.RESULTS]['genomic_biomarkers']['HRD']

        if hrd_results['Genomic biomarker alteration'] == 'HRD':
            result_text = self.TEXT

            # Check if HRD is listed in the treatment options merger
            treatment_options = report[self.PLUGINS][gl].get('merge_inputs', {}).get('treatment_options_merger', [])
            for treatment in treatment_options:
                if treatment.get('Gene') == 'HRD':
                    cancer_type = report[self.PLUGINS]['case_overview'][self.RESULTS]['primary_cancer'].lower()
                    result_text += f" HRD is an NCCN-listed biomarker for {cancer_type}. "
                    break  # No need to loop once we find the HRD entry

            return result_text
        else:
            return ''

class msi_blurb_maker(blurb_base):
    # make a blurb section for MSI status, if applicable

    def run(self, report):
        gl = 'genomic_landscape'
        MSI_results = report[self.PLUGINS][gl][self.RESULTS]['genomic_biomarkers']['MSI']
        alteration = MSI_results['Genomic biomarker alteration']

        if alteration == 'INCONCLUSIVE':
            return "Genomic biomarker analysis returned inconclusive results for microsatellite instability (MSI-inconclusive). "
        elif alteration == 'MSI-H':
            return "Genomic biomarker analysis returned results consistent with microsatellite instability (MSI-H) and a high tumour mutational burden (TMB-H). "
        else:
            return ''


class preamble_maker(blurb_base):
    # make a blurb preamble with values filled in from JSON

    TEMPLATE = "The patient has been diagnosed with ${cancer_type} and has been referred "+\
        "for the OICR Genomics ${assay} assay through the ${study} study. The tumor had "+\
        "an estimated ploidy of ${ploidy} and the percent genome altered (PGA) was ${pga}%"

    def run(self, report):
        my_template = Template(self.TEMPLATE)
        case = report[self.PLUGINS]['case_overview'][self.RESULTS]
        ploidy = report[self.PLUGINS]['sample'][self.RESULTS]['Estimated Ploidy']
        pga = report[self.PLUGINS]['wgts.cnv_purple'][self.RESULTS]['percent genome altered']
        values = {
            'cancer_type': case['primary_cancer'].lower(),
            'assay': case['assay'],
            'study': case['study'],
            'ploidy': ploidy,
            'pga': pga
        }
        preamble = my_template.substitute(values)
        if pga >= 40:
            preamble = preamble+', suggestive of substantial structural variation. '
        else:
            preamble = preamble+'. '
        return preamble

class snv_indel_blurb_maker(blurb_base):

    TEMPLATE = 'Small mutation analysis detected ${total} somatic '+\
        '${variant_string}: ${variant_list}. '

    def make_variant_list(self, report):
        body = report[self.PLUGINS]['wgts.snv_indel'][self.RESULTS][self.BODY_TC]
        variants = []
        first = True
        for i, variant in enumerate(body):
            gene = '_{0}_'.format(variant['Gene'])
            protein = escape(variant['protein']).replace("*", "&#42;")
            variant_type = variant['type'].lower()
            if not re.search('mutation', variant_type):
                variant_type = variant_type+' mutation'

            # Check if gene sounds like it starts with a vowel (e.g., NF1, MSH6, etc.)
            first_letter = variant['Gene'][0].upper()
            article = 'an' if first_letter in ['A', 'E', 'F', 'H', 'I', 'L', 'M', 'N', 'O', 'R', 'S', 'X'] else 'a'
            v = f'{article} {gene} ({protein}) {variant_type}'

            if variant['LOH']:
                v += ' with LOH'
            variants.append(v)
        return variants

    def run(self, report):
        total = report[self.PLUGINS]['wgts.snv_indel'][self.RESULTS]['oncogenic mutations']
        variant_list = self.make_variant_list(report)
        variant_string = 'variant' if total == 1 else 'variants'

        if len(variant_list) > 0:
            values = {
                'total': self.number_to_words(total),
                'variant_list': self.comma_separated_with_and(variant_list),
                'variant_string': variant_string
            }
            snv_indel_text = Template(self.TEMPLATE).substitute(values)
        else:
            snv_indel_text = ''
        return snv_indel_text

if __name__ == '__main__':
    report = json.loads(sys.stdin.read())
    print(preamble_maker().run(report), end='')
    print(cnv_blurb_maker().run(report), end='')
    print(snv_indel_blurb_maker().run(report), end='')
    print(fusion_blurb_maker().run(report), end='')
    print(hrd_blurb_maker().run(report), end='')
    print(msi_blurb_maker().run(report), end='')
    print(conclusion_maker().run(report))
