process PLOTSAMTOOLSSTATS {
    tag "$meta.id"
    label 'process_single'

    conda "mulled-v2-3f3213e89b19c0f0d2ac7dab819855ab60854fcf"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-3f3213e89b19c0f0d2ac7dab819855ab60854fcf:6d8172f377c9eb1fb81ffc0bd5a7c159b221a4b1-0':
        'biocontainers/mulled-v2-3f3213e89b19c0f0d2ac7dab819855ab60854fcf:6d8172f377c9eb1fb81ffc0bd5a7c159b221a4b1-0' }"

    input:
    tuple val(meta), path(stats)

    output:
    tuple val(meta), path("*.pdf"), emit: pdf
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
   
    """
    cat $stats | grep ^SN | cut -f 2- | sed "s/\$/\t!{meta.lineage}\t!{meta.id}/" > ${prefix}.txt
    
    plot_sam_stats.R ${prefix}.txt ${prefix}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
