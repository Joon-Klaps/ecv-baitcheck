## Introduction

**ecv/baitcheck** is a bioinformatics pipeline that ...

1. Map baits to reference ([`BWA-MEM2`](https://github.com/bwa-mem2/bwa-mem2))
2. Get mapping stats using various [`Samtools`](http://www.htslib.org/doc/samtools.html) modules
   1. [`Sort`](http://www.htslib.org/doc/samtools-sort.html)
   2. [`Stats`](http://www.htslib.org/doc/samtools-stats.html)
   3. [`Flagstats`](http://www.htslib.org/doc/samtools-flagstat.html)
   4. [`Idxstats`](http://www.htslib.org/doc/samtools-idxstats.html)
   5. [`Depth`](http://www.htslib.org/doc/samtools-depth.html)
3. Plot bait depth-coverage to reference ([`R`](https://www.r-project.org/))
4. Create summary report ([`MultiQC`](https://multiqc.info/))

## Usage

> **Note**
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how
> to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline)
> with `-profile test` before running the workflow on actual data.

Now, you can run the pipeline using:

```bash
nextflow run ecv/baitcheck \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --baits path/to/baits.fasta \
   --outdir <OUTDIR>
```

> **Warning:**
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those
> provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

## Credits

ecv/baitcheck was originally written by @Joon-Klaps.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).
