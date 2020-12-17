### Genome simulator

This script is designed to take known genomes (ones youve download from a repository perhaps)
and create simulated reads from these genomes. It then will align these reads to a metagenome 
supplied by the user.

One potential usefulness of this is when you have a metagenomic assembly for which you wish
to search it for a particular organism that did not get annotated sufficiently. Here you can 
create a subset of reads from the organism (or even gene/operon) you want to search for (or organisms! just make them
all one fasta file!) and this program will tell you which, if any, contigs in your metagenome have
matches.

	1. Runs using BBMAP (v37.50) and SAMTOOLS (v1.9)
	2. Usage:
		./genome_simulator.sh [FASTA] [REFERENCE]
		FASTA: a fasta file to generate random
		        reads from, in order to map to a
		        metagenome.
		REFERENCE: fasta file of your metagenome you
		           want to align the simulated reads
		           to
	3. runs using 2 cores, uses ~ 2GB of memory (some parts can be modified to use less)
	
	
### Output
Below you can see that 1430 reads mapped to contig c_000000002592! Wow! In this example
contig c_000000002592 wasnt annotated further than Bacteria by the anntation software. But 
stick that little guy into BLASTn and you have all kinds of close hits!

c_000000002592	22035	**1430**	0

c_000000005492	14790	1069	0

c_000000002093	3483	974	0

c_000000004920	49243	922	0

c_000000003728	34774	760	0

## what was once lost, is now found.

