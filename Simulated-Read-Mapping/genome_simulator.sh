#!/bin/bash

#    .---------- constant part!
#    vvvv vvvv-- the code from above
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
#printf "I ${RED}love${NC} Stack Overflow\n"

printf "
USAGE:
	./genome_simulator.sh [FASTA] [REFERENCE]
		-FASTA: a fasta file to generate random
		        reads from, in order to map to a 
		        metagenome.
"

if [ -n "$1" ]; then
  printf "$1 File being used to simulate reads"
  printf "$2 File is being used to map reads to"
else
  printf "No fasta file supplied"
  exit 1
fi

printf "
${RED}#########################################
THIS WILL OVERWRITE A PREVIOUS SIMULATION
##########################################${NC}"
sleep 5

rm bs_mapped.sh
rm simulated*
rm -r ref/

module load BBMap/37.50
module load samtools/1.9


printf "
${CYAN}##################################################
Detecting number of contigs in simulation fasta...
##################################################${NC}"

NCONTIGS=$(grep -c "^>" "$1")
if [ $NCONTIGS > 1 ]; then
	printf "
	${CYAN}###############################
	More than one contig, fusing...
	###############################${NC}"
	fuse.sh in=$1 out=$1.fused.fasta
	printf "
	${CYAN}########################
	Creating random reads...
	#########################${NC}"
	randomreads.sh ref=$1.fused.fasta out=simulated_reads.fq len=150 reads=500000
else
	printf "
	${CYAN}##########################
	Creating random reads...
	##########################${NC}"
	randomreads.sh ref=$1 out=simulated_reads.fq len=150 reads=500000
fi

printf "
${CYAN}###########
cleaning...
###########${NC}"
mkdir -p intermediate_files
mv $1* intermediate_files/
rm -r ref/

printf "
${CYAN}##################
Making reference...
###################${NC}"

bbmap.sh ref=$2

bbmap.sh \
in1=simulated_reads.fq \
interleaved=auto \
threads=2 \
out=simulated_map.bam \
bs=bs_mapped.sh

printf "
${CYAN}##############
Sorting bam...
##############${NC}"
bash bs_mapped.sh

printf "
${CYAN}##############
Counting reads...
################${NC}"
samtools idxstats --threads 2 simulated_map_sorted.bam > simulated_read_counts

sort -k3,3nr simulated_read_counts | head
rm 1



