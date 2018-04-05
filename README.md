# AutoEVM

## Description:

  Autorun Evidence Modeler

## Version

  v20150521

## Descriptions:

  Running Evidence Modeler
  1. Partition: partition_EVM_inputs.pl
  2. Commands : write_EVM_commands.pl
  3. Excute   : execute_EVM_commands.pl
  4. Recombine: recombine_EVM_partial_outputs.pl
  5. Convert  : convert_EVM_outputs_to_GFF3.pl

## Options:

>  -h    Print this help message
>
>  -g	*Genome file in fasta
>
>  -p	*Gene prediction in GFF3
>
>  -e	*EST alignments in GFF3
>
>  -a	*Protein alignments in GFF3
>
>  -w	*Weights file (3 column)
>
>  -r	Repeats in GFF when masking genome
>
>  -d    debug mode, more detail

## Example:
  $0 -g genome.fa -p abinitio.gff3 -e est.gff3 -a AA.gff3 -w weights.txt

## Author:

>  Fu-Hao Lu
>
>  Post-Doctoral Scientist in Micheal Bevan laboratory
>
>  Cell and Developmental Department, John Innes Centre
>
>  Norwich NR4 7UH, United Kingdom
>
>  E-mail: Fu-Hao.Lu@jic.ac.uk
