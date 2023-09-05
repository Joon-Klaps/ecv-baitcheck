process SAMTOOLSSTATSEXTRACT {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::samtools=1.17"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--h00cdaf9_0' :
        'biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta), path(stats)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv       // stat_name, stat_value, sample_id, lineage
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat ${stats} | grep ^SN | cut -f 2- | sed 's/\t\\#.*\$//;s/\$/\t${prefix}\t${meta.lineage}/' > ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        grep: \$(echo \$(grep --version 2>&1) | head -n1 | sed 's/.*\\)//' ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        grep: \$(echo \$(grep --version 2>&1) | head -n1 | sed 's/.*\\)//' ))
    END_VERSIONS
    """
}
