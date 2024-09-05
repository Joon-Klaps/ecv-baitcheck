/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

baits = Channel.fromPath(params.baits, checkIfExists: true)
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQ_ALIGN_BWAMEM2 } from '../subworkflows/local/fastq_align_bwamem2'

//
// MODULE: Installed directly from nf-core/modules
//
include { BWAMEM2_INDEX                } from '../modules/nf-core/bwamem2/index/main'
include { SAMTOOLS_DEPTH               } from '../modules/nf-core/samtools/depth/main'
include { KAIJU_KAIJU                  } from '../modules/nf-core/kaiju/kaiju/main'
include { KAIJU_KAIJU2TABLE            } from '../modules/nf-core/kaiju/kaiju2table/main'
include { UNTAR                        } from '../modules/nf-core/untar/main'
include { PLOTBEDCOVERAGE              } from '../modules/local/plotbedcoverage'
include { SAMTOOLSSTATSEXTRACT         } from '../modules/local/samtoolsstatsextract'
include { CAT_CAT as CAT_CAT_STATS     } from '../modules/nf-core/cat/cat/main'
include { CAT_CAT as CAT_CAT_COVERAGE  } from '../modules/nf-core/cat/cat/main'
include { PLOTSAMTOOLSSTATS            } from '../modules/local/plotsamtoolsstats'
include { CUSTOM_DUMPSOFTWAREVERSIONS  } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { MULTIQC                      } from '../modules/nf-core/multiqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow BAITCHECK {

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    // Importing samplesheet
    ch_samplesheet = Channel.fromSamplesheet('input') // channel [ val(meta), path(reference)]

    //Building the references
    ch_index = BWAMEM2_INDEX(ch_samplesheet).index

    if (params.kaiju_db.endsWith('.tgz')) {

        // Downloading the kaiju database
        UNTAR (
            Channel.of([[id:"kaiju"], file(params.kaiju_db, checkIfExists: true) ])
        )
        ch_versions      = ch_versions.mix(UNTAR.out.versions)
        kaiju_db = UNTAR.out.untar.map{meta, path -> path}.collect()
    } else {
        kaiju_db = Channel.fromPath(params.kaiju_db, checkIfExists: true)
    }

    baits_meta = baits.map{baits -> [[ id: 'baits' ], baits ]}
    // Check annotation of baits
    KAIJU_KAIJU( baits_meta, kaiju_db)
    ch_versions      = ch_versions.mix(KAIJU_KAIJU.out.versions)

    KAIJU_KAIJU2TABLE( KAIJU_KAIJU.out.results, kaiju_db, params.kaiju_rank)
    ch_versions      = ch_versions.mix(KAIJU_KAIJU2TABLE.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(KAIJU_KAIJU2TABLE.out.summary.collect{it[1]}.ifEmpty([]))

    // some swapping of annotation data
    ch_index_baits = ch_index.combine(baits).join(ch_samplesheet,by:[0])

    ch_baits = ch_index_baits.map{ meta, index, baits, fasta -> [ meta, baits ] }
    ch_index = ch_index_baits.map{ meta, index, baits, fasta -> [ meta, index ] }
    ch_ref   = ch_index_baits.map{ meta, index, baits, fasta -> [ meta, fasta ] }


    // Aligning the reads
    FASTQ_ALIGN_BWAMEM2 (
        ch_baits,
        ch_index,
        false,
        ch_ref
    )
    ch_versions      = ch_versions.mix(FASTQ_ALIGN_BWAMEM2.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix( FASTQ_ALIGN_BWAMEM2.out.stats.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix( FASTQ_ALIGN_BWAMEM2.out.flagstat.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix( FASTQ_ALIGN_BWAMEM2.out.idxstats.collect{it[1]}.ifEmpty([]))

    SAMTOOLS_DEPTH (
        FASTQ_ALIGN_BWAMEM2.out.bam,
        [[:],[]]
    )
    ch_versions      = ch_versions.mix(SAMTOOLS_DEPTH.out.versions)

    // combine all the coverage into a single file
        coverage_combined = SAMTOOLS_DEPTH.out.tsv
            .collect{it[1]}
            .map{it -> [[id: 'coverage_combined'], it]}

        CAT_CAT_COVERAGE ( coverage_combined )
        ch_versions      = ch_versions.mix(CAT_CAT_COVERAGE.out.versions)

        PLOTBEDCOVERAGE (
            CAT_CAT_COVERAGE.out.file_out
        )
        ch_versions     = ch_versions.mix(PLOTBEDCOVERAGE.out.versions)

    // combine all the stats into a single file ... wow deja vu
        SAMTOOLSSTATSEXTRACT (
            FASTQ_ALIGN_BWAMEM2.out.stats
        )
        ch_versions      = ch_versions.mix(SAMTOOLSSTATSEXTRACT.out.versions)
        stats_combined   = SAMTOOLSSTATSEXTRACT.out.tsv
            .collect{it[1]}
            .map{it -> [[id: 'stats_combined'], it]}

        CAT_CAT_STATS (
            stats_combined
        )
        ch_versions      = ch_versions.mix(CAT_CAT_STATS.out.versions)

    PLOTSAMTOOLSSTATS (
        CAT_CAT_STATS.out.file_out
    )
    ch_versions     = ch_versions.mix(PLOTSAMTOOLSSTATS.out.versions)


    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )


    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowBaitcheck.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowBaitcheck.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
