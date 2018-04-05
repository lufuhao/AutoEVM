#!/bin/bash
RunDir=$(cd `dirname $(readlink -f $0)`; pwd)
MachType=$(uname -m)

################# help message ######################################
help()
{
cat<<HELP

$0 --- Autorun Evidence Modeler

Version: 20150521

Descriptions:
  Running Evidence Modeler
    1. Partition: partition_EVM_inputs.pl
    2. Commands : write_EVM_commands.pl
    3. Excute   : execute_EVM_commands.pl
    4. Recombine: recombine_EVM_partial_outputs.pl
    5. Convert  : convert_EVM_outputs_to_GFF3.pl

Options:
  -h    Print this help message
  -g	*Genome file in fasta
  -p	*Gene prediction in GFF3
  -e	*EST alignments in GFF3
  -a	*Protein alignments in GFF3
  -w	*Weights file (3 column)
  -r	Repeats in GFF when masking genome
  -d    debug mode, more detail

Example:
  $0 -g genome.fa -p abinitio.gff3 -e est.gff3 -a AA.gff3 -w weights.txt

Author:
  Fu-Hao Lu
  Post-Doctoral Scientist in Micheal Bevan laboratory
  Cell and Developmental Department, John Innes Centre
  Norwich NR4 7UH, United Kingdom
  E-mail: Fu-Hao.Lu@jic.ac.uk
HELP
exit 0
}
[ -z "$1" ] && help
[ "$1" = "-h" ] && help
[ "$1" = "--help" ] && help
#################### Defaults #######################################
echo -e "\n######################\nProgram initializing ...\n######################\n"
#echo "Adding $RunDir/bin into PATH"
#export PATH=$RunDir/bin:$RunDir/utils/bin:$PATH



################### Parameter defaults ##############################
debug=0
###Patition###
genome=''
genepredictions=''
estalignments=''
proteinalignment=''
#segmentsize=100000/500000
segmentsize=500000
overlapsize=10000
partitionlist="EVM.partitions_list.out"
### Write cmd ###
weightsfile=''
evm_write_out='EVM.out'
commandlist='EVM.commands.list'
repeats=''
### execute
logfile='EVM.execute.log'
### recombine
recombineout='EVM.recombine.out'
### Convert
convertout='EVM.final.merge.gff'

#################### parameters #####################################
while [ -n "$1" ]; do
  case "$1" in
    -h) help;shift 1;;
    -g) genome=$2;shift 2;;
    -p) genepredictions=$2;shift 2;;
    -e) estalignments=$2;shift 2;;
    -a) proteinalignment=$2;shift 2;;
    -w) weightsfile=$2; shift 2;;
    -r) repeats=$2; shift 2;;
    -d) debug=1; shift 1;;
    --) shift;break;;
    -*) echo "error: no such option $1. -h for help" > /dev/stderr;exit 1;;
    *) break;;
  esac
done



#################### Subfuctions ####################################
###Detect command existence
CmdExists () {
  if command -v $1 >/dev/null 2>&1; then
    echo 0
  else
#    echo "I require $1 but it's not installed.  Aborting." >&2
    echo 1
  fi
#  local cmd=$1
#  if command -v $cmd >/dev/null 2>&1;then
#    echo >&2 $cmd "  :  "`command -v $cmd`
#    exit 0
#  else
#    echo >&2 "Error: require $cmd but it's not installed.  Exiting..."
#    exit 1
#  fi
}



#################### Command test ###################################
declare -a cmdlist=('partition_EVM_inputs.pl' 'write_EVM_commands.pl' 'execute_EVM_commands.pl' 'recombine_EVM_partial_outputs.pl' 'convert_EVM_outputs_to_GFF3.pl')
declare -a newcmdlist=()
for ind_cmd in ${cmdlist[@]}; do
	if [ $(CmdExists "$ind_cmd") -eq 1 ]; then
		if [ -z "$EVM_HOME" ] || [ ! -d $EVM_HOME ]; then
			echo "Error: script '$ind_cmd' in PROGRAM 'EVM'  is required but not found.  Aborting..." >&2 
			exit 127
		elif [ -s "$EVM_HOME/EvmUtils/$ind_cmd" ]; then
			if [ $debug -eq 1 ]; then
				echo "Found cmd $ind_cmd in $EVM_HOME/EvmUtils/$ind_cmd"
			fi
			newcmdlist+=("$EVM_HOME/EvmUtils/$ind_cmd")
		fi
	else
		newcmdlist+=("$ind_cmd")
	fi
done
if [ ${#newcmdlist[@]} -ne 5 ]; then
	echo "Error: some commsnds missing" >&2
	exit 127
else
	if [ $debug -eq 1 ]; then
		echo "1. Partition: ${newcmdlist[0]}"
		echo "2. Write cmd: ${newcmdlist[1]}"
		echo "3. Execute  : ${newcmdlist[2]}"
		echo "4. Recombine: ${newcmdlist[3]}"
		echo "5. Convert  : ${newcmdlist[4]}"
	fi
fi




#################### Defaults #######################################




#################### Input and Output ###############################
if [ ! -s $genome ]; then
	echo "Error: invalid genome file: $genome" >&2
	exit 1
fi
if [ ! -s $genepredictions ]; then
	echo "Error: invalid gene prediction file: $genepredictions" >&2
	exit 1
fi
if [ ! -s $estalignments ]; then
	echo "Error: invalid gene prediction file: $estalignments" >&2
	exit 1
fi
if [ ! -s $proteinalignment ]; then
	echo "Error: invalid gene prediction file: $proteinalignment" >&2
	exit 1
fi
if [ ! -s $weightsfile ]; then
	echo "Error: invalid gene prediction file: $weightsfile" >&2
	exit 1
fi

if [ $debug -eq 1 ]; then
	echo -e "\n\n\n"
	echo "Genome : $genome"
	echo "abintio: $genepredictions"
	echo "EST    : $estalignments"
	echo "Protein: $proteinalignment"
	if [ ! -z "$repeats" ] && [ -s $repeats ]; then
		echo "Repeats: $repeats"
	fi
	echo "Weights: $weightsfile"
fi



#################### Main ###########################################
##### 1. partition_EVM_inputs.pl parameters #####
#--genome                * :fasta file containing all genome sequences
#--gene_predictions      * :file containing gene predictions
#--protein_alignments      :file containing protein alignments
#--transcript_alignments   :file containing transcript alignments
#--pasaTerminalExons       :file containing terminal exons based on PASA long-orf data.
#--repeats                 :file containing repeats to be masked
#--segmentSize           * :length of a single sequence for running EVM
#--overlapSize           * :length of sequence overlap between segmented sequences
#--partition_listing     * :name of output file to be created that contains the list of partitions
#To reduce memory requirements, the --segmentSize parameter should be set to less than 1 Mb. 
#The --overlapSize should be set to a length at least two standard deviations greater than the expected gene length, to minimize the likelihood of missing a complete gene structure within any single segment length.
echo "Step1: partition"
partition_EVM_inputs.pl --genome $genome \
     --gene_predictions $genepredictions \
     --protein_alignments $proteinalignment \
     --transcript_alignments $estalignments \
     --segmentSize $segmentsize --overlapSize $overlapsize --partition_listing $partitionlist
if [ $? -ne 0 ] || [ ! -s $partitionlist ]; then
	echo "Error: 1. partition_EVM_inputs.pl running or output error"
	exit 1
fi


##### 2. write_EVM_commands.pl parameters #####
#  Required:
#  --partitions               partitions file 
#
#  Base File Names:
#  --genome           		| -G   genome sequence in fasta format
#  --gene_predictions       | -g   gene predictions gff3 file
#  --protein_alignments 	| -p  protein alignments gff3 file
#  --transcript_alignments  | -e    est alignments gff3 file
#  --repeats          		| -r    gff3 file with repeats masked from genome file
#  --terminalExons    		| -t   supplementary file of additional terminal exons to consider (from PASA long-orfs)
#  --output_file_name 		| -O   name of output file to be written to in the directory containing the inputs
#  ** Files with full and fixed paths ** :
#
#  --weights          | -w    weights for evidence types file
#
#  Optional arguments:
#  --stop_codons             list of stop codons (default: TAA,TGA,TAG)
#                            *for Tetrahymena, set --stop_codons TGA
#  --min_intron_length       minimum length for an intron (default 20 bp)
#
# flags:
#  --forwardStrandOnly   runs only on the forward strand
#  --reverseStrandOnly   runs only on the reverse strand
#  -S                    verbose flag
#  --debug               debug mode, writes lots of extra files.
#
#  Misc:
#  --search_long_introns  <int>  when set, reexamines long introns (can find nested genes, but also can result in FPs) (default: 0 (off))
#  --re_search_intergenic <int>  when set, reexamines intergenic regions of minimum length (can add FPs) (default: 0  (off))
#  --terminal_intergenic_re_search <int>   reexamines genomic regions outside of the span of all predicted genes (default: 10000)
echo "Step2: write cmd"
if [ ! -z "$repeats" ] && [ -s $repeats ]; then
	echo "Repeats: $repeats"
	write_EVM_commands.pl --genome $genome \
	--gene_predictions $genepredictions \
	--transcript_alignments $estalignments \
	--protein_alignments  $proteinalignment \
	--repeats $repeats
	--weights $weightsfile \
	--output_file_name $evm_write_out \
	--partitions $partitionlist > $commandlist
else
	echo "Info: Running without repeats"
	write_EVM_commands.pl --genome $genome \
	--gene_predictions $genepredictions \
	--transcript_alignments $estalignments \
	--protein_alignments  $proteinalignment \
	--weights $weightsfile \
	--output_file_name $evm_write_out \
	--partitions $partitionlist > $commandlist
fi
if [ $? -ne 0 ] || [ ! -s $commandlist ]; then
	echo "Error: 2. write_EVM_commands.pl running or output error"
	exit 1
fi



### 3. execute_EVM_commands.pl ###
echo "Step3: execuate cmds"
execute_EVM_commands.pl $commandlist | tee $logfile
if [ $? -ne 0 ]; then
	echo "Error: 3. execute_EVM_commands.pl running error"
	exit 1
fi



### 4. recombine_EVM_partial_outputs.pl ###
echo "Step4: recombine"
recombine_EVM_partial_outputs.pl --partitions $partitionlist --output_file_name $recombineout
if [ $? -ne 0 ]; then
	echo "Error: 4. recombine_EVM_partial_outputs.pl running or output error"
	exit 1
fi



### 5. convert_EVM_outputs_to_GFF3.pl ###
echo "Step5: convert"
convert_EVM_outputs_to_GFF3.pl  --partitions $partitionlist --output $convertout --genome $genome
if [ $? -ne 0 ] || [ ! -s $convertout ]; then
	echo "Error: 5. convert_EVM_outputs_to_GFF3.pl running or output error"
	exit 1
fi

exit 0
