### Genome simulator
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
	