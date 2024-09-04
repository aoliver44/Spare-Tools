#!/bin/bash

# practice command
# bash read2contigtaxa.sh -d /share/lemaylab-backedup/sblecksmith/FL100_metagenomes/CAZy_diamond/7090.txt -r /share/lemaylab/jalarke/FL100_metagenomes/NovaSeq792/step4_flash/7090.extendedFrags.fastq -c /share/lemaylab-backedup/FL100_step8_assemblies/NovaSeq792/7090_assembled/final.contigs.fa -f GH86 -o /share/lemaylab/aoliver/sarah_gh/playground -t 8

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Match genes found in Diamond output to taxonomy derived from contigs."
   echo
   echo "Syntax: read2contigtaxa.sh [-d|c|o|r|t|h]"
   echo "Usage: bash read2contigtaxa.sh -d /path/to/diamond.txt -r /path/to/reads.fa"
   echo "            -c /path/to/contigs.fa -o /path/to/workdir"
   echo "options:"
   echo "d     Full path to diamond text file."
   echo "r     Full path to reads file."
   echo "c     Full path to contig file."
   echo "o     Full path to workdir."
   echo "f     Regex filter for alignment subjects."
   echo "t     Enter number of cores to use."
   echo "h     Print this help message."
   echo
}

## set some default variables
FILT="none"

## What some of these files should look like:
# your diamond alignment file should look like this:
#A01535:301:H5TFNDSX7:4:1262:16423:28682	ALK86697.1|GH2|	100.0	81	0	0	2244	690	770	5.0e-41	169.5
#A01535:301:H5TFNDSX7:4:2525:24198:11115	ALB75843.1|CBM20|GH77|	100.0	95	0	02	286	216	310	1.2e-49	198.4
#	Note the above column1 is the name of the read, which matches a read in the path/to/reads.fa
#	Note the above column2 is a hit to a database. It should have some string for -f to match to.
#		If not, it will just search all lines in read file

# your contig file should look like this
#>k141_20230 flag=1 multi=2.0000 len=322
#CTATTTCTTTATTATCGTTCAGTCTTACAGCCATGATGTTTTC
#	Note the fasta name has a contig name in postion 1 and length in position 4


############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts "hd:r:c:o:f:t:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      d) # Enter a name
         DIAMOND=$OPTARG;;
      r) # Enter a name
         READS=$OPTARG;;
      c) # Enter a name
         CONTIGS=$OPTARG;;
      o) # Enter a name
         OUTDIR=$OPTARG;;
      f) # Enter a name
         FILTER=$OPTARG;;
      t) # Enter a name
         CORES=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         Help
         exit;;
   esac
done

############################################################
# Main Program.                                            #
############################################################

## load up necessary modules
module load /software/modules/1.923/lssc0-linux/modulefiles/blast/2.14.1+
module load /software/modules/modulefiles_static/bbmap/38.87

## Echo parameters
## create var name based on diamond alignment file
subject=$(basename ${DIAMOND} .txt)
echo "Subject name used (from diamond file): " ${subject}
echo "Output directory is: " ${OUTDIR}

## make tmp dir to work in
mkdir -p ${OUTDIR}/tmp_${subject}
WORKDIR=${OUTDIR}/tmp_${subject}/

## get gene seqeuences from diamond
echo "Diamond alignment file found here: " ${DIAMOND}
cut -f1,2 ${DIAMOND} > ${WORKDIR}tmp_read_names

## only grab what is filtered for
if [ ${FILTER} == "none" ]; then
echo "No filter specified, looking at all reads in diamond file. This may take a long time..."
else
echo "Filter being used: " ${FILTER}
grep -F "${FILTER}|" ${WORKDIR}tmp_read_names > ${WORKDIR}tmp_read_names_filt
echo "Number of filtered hits to search for: " $(grep -c "${FILTER}" ${WORKDIR}tmp_read_names)
rm ${WORKDIR}tmp_read_names
mv ${WORKDIR}tmp_read_names_filt ${WORKDIR}tmp_read_names
fi

## find the sequences from the reads
echo "Looking for reads by names found in alignment file..."
cut -f1 ${WORKDIR}tmp_read_names > ${WORKDIR}tmp_read_names_only
filterbyname.sh in=${READS} out=${WORKDIR}fasta_to_map.fasta names=${WORKDIR}tmp_read_names_only include=t
echo "Done! Found the reads, and output to:  " ${WORKDIR}fasta_to_map.fasta

## create contig db for blast
echo "Making blastn database..."
file ${CONTIGS} > ${WORKDIR}tmp_info1
if grep -q "gzip" ${WORKDIR}tmp_info1; then echo "Contigs file compressed. Please uncompress before proceeding"; exit; fi

makeblastdb -in ${CONTIGS} -input_type fasta -dbtype nucl -out ${WORKDIR}${subject}_blastdb

## blast reads against DB
echo "Blasting reads..."
blastn -query ${WORKDIR}fasta_to_map.fasta -db ${WORKDIR}${subject}_blastdb -outfmt 6 -max_target_seqs 1 -max_hsps 1 -num_threads ${CORES} -out ${WORKDIR}${subject}.blastout
echo "Output written to: " ${WORKDIR}${subject}.blastout

## Grab the contigs identifed from the blast
echo "Looking for contigs which the reads mapped to..."
cut -f2 ${WORKDIR}${subject}.blastout | uniq > ${WORKDIR}${subject}.blastout.contignames
filterbyname.sh in=${CONTIGS} out=${WORKDIR}contigs_to_identify.fasta names=${WORKDIR}${subject}.blastout.contignames include=t
echo "Done! Found the contigs, and output to:  " ${WORKDIR}fasta_to_map.fasta

## assign taxonomy to those contigs (borrowed most of this from Zeya's script)
# Software paths
CAT=/share/lemaylab-backedup/milklab/programs/CAT-5.0.3/CAT_pack/CAT # CAT version and database to be updated soon!
CATdb=/share/lemaylab-backedup/milklab/database/CAT_prepare_20190719
progdigal=/software/prodigal/2.6.3/x86_64-linux-ubuntu14.04/bin/prodigal
diamond=/share/lemaylab-backedup/milklab/programs/diamond

# for help /share/lemaylab-backedup/milklab/programs/CAT-5.0.3/CAT_pack/CAT contigs -h
# https://github.com/dutilh/CAT
echo "Assigning taxonomy to the contigs..."
$CAT contigs -c ${WORKDIR}contigs_to_identify.fasta -d $CATdb/2019-07-19_CAT_database -t $CATdb/2019-07-19_taxonomy --path_to_prodigal $progdigal --path_to_diamond $diamond -o ${WORKDIR}${subject}_CAT -n ${CORES}
$CAT add_names -i ${WORKDIR}${subject}_CAT.contig2classification.txt -o ${WORKDIR}${subject}_CAT.taxaid.txt -t $CATdb/2019-07-19_taxonomy --only_official
cut -f1,6-13 ${WORKDIR}${subject}_CAT.taxaid.txt | grep -v "#" | sed "s/\t/|/g" | sed "s/:/|/g" | sed "s/ //g" > ${WORKDIR}${subject}_CAT.taxaid.txt.SUMMARY
echo "Done! Taxonomy assigned."

## get full output file
cut -f1-2 ${WORKDIR}${subject}.blastout > ${WORKDIR}${subject}.blastout.tmp
while read read_name contig_name; do echo ${subject} ${contig_name} $(grep -F -m 1 "${read_name}" ${DIAMOND} | sed "s/|/_/g"); done < ${WORKDIR}${subject}.blastout.tmp > ${WORKDIR}${subject}.blastout.tmp2

## remove a lot of stuff that just isnt necessary
cut -f1-4 -d' ' ${WORKDIR}${subject}.blastout.tmp2 | sed "s/ /|/g" > ${WORKDIR}${subject}.blastout.tmp3

## convert spaces to "|" for common delim
while read read_name contig_name; do
echo $(grep -F -m 1 "${read_name}" ${WORKDIR}${subject}.blastout.tmp3)$'|'$(grep -F -m 1 "${contig_name}" ${WORKDIR}contigs_to_identify.fasta | cut -f4 -d' ')$'|'$(grep -F -m 1 "${contig_name}" ${WORKDIR}/${subject}_CAT.taxaid.txt.SUMMARY)
done < ${WORKDIR}${subject}.blastout.tmp > ${WORKDIR}${subject}_fullout.txt

## what the output coluumns mean
## first several are diamond columns
#contig_name read_name database_name bitscore qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore contig_length contig_name kingdom kingdom_confidence phylum phylum_confidence class class_confidence order order_confidence family family_confidence genus genus_confidence species species_condifence

rm ${WORKDIR}${subject}*blastdb*

echo "Done!!"

# ## to read into R, here is some ideas. Paths need to change:
# library(readr)
# library(dplyr)
# library(tidyr)
# library(tibble)

# ## read in df
# colnames <- c("subject_id", "contig_name", "read_name", "cazy_db_hit", "contig_legth", "contig_name_dup", "kingdom", "k_conf", "phylum", "p_conf", "class", "c_conf", "order", "o_conf", "family", "f_conf", "genus", "g_conf", "species", "s_conf")
# gh_output <- readr::read_delim(file = "/home/data/7090_fullout.txt", delim = "|", col_names = colnames)

# ## remove columns that are probably unnessary
# gh_output <- gh_output %>% dplyr::select(., -dplyr::any_of(c("k_conf", "p_conf", "c_conf", "o_conf", "f_conf", "g_conf", "s_conf", "contig_name_dup")))

# ## seperate the cazy_db_hit
# gh_output <- gh_output %>% tidyr::separate(., col = cazy_db_hit, sep = "_", into = c("gene", "CAZyme", "EC", "Extra", "Extra2"), extra = "merge")