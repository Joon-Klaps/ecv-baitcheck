process PLOTBEDCOVERAGE {
    tag "$meta.id"
    label 'process_single'

    conda "mulled-v2-3f3213e89b19c0f0d2ac7dab819855ab60854fcf"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-3f3213e89b19c0f0d2ac7dab819855ab60854fcf:6d8172f377c9eb1fb81ffc0bd5a7c159b221a4b1-0':
        'biocontainers/mulled-v2-3f3213e89b19c0f0d2ac7dab819855ab60854fcf:6d8172f377c9eb1fb81ffc0bd5a7c159b221a4b1-0' }"

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path("*.pdf"), emit: pdf
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
   
    """
    plot_bed_coverage.R ${bed} ${prefix}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.pdf
    """
}
