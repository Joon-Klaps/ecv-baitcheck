process PLOTBEDCOVERAGE {
    tag "$meta.id"
    label 'process_single'

    conda "mulled-v2-a1e116d3536834ecbbada3c89e7eb04341cbc496"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-a1e116d3536834ecbbada3c89e7eb04341cbc496:4825d9b0ce09150fdee454e83ca2f24e2f7e952c-0':
        'biocontainers/mulled-v2-a1e116d3536834ecbbada3c89e7eb04341cbc496:4825d9b0ce09150fdee454e83ca2f24e2f7e952c-0' }"

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
