#!/bin/bash

echo "
#####################################
 __               __         _____
|_    _  _  _ |  |__)|   /\ (_  |
| |_|| )(_)(_||  |__)|__/--\__) |
        _/
#####################################

#################################################
If the script fails, might i suggest reading the
README.txt file?? Good luck my friend.
#################################################
"

sleep 5

## Make an output folder

## Define some variables - how many reads in the metagenome,
## a working directory to put stuff in, and a simplier name for,
## the metagenomes.
BASEDIR=$PWD
mkdir $PWD/fungal_outs
WORKDIR=$PWD/fungal_outs/

cd ${WORKDIR}
wget https://hpc.oit.uci.edu/~aoliver2/normalize_fungal_counts.sh
chmod +x normalize_fungal_counts.sh
BLAST_DB=/dfs3/bio/aoliver2/database/fungal_blast/fb_database.fna

cd ${BASEDIR}
counter=1
total_files=$(ls -1q *.filter.clean.merged.fq.gz | wc -l)

## Pseudo array job script: write script to write scripts. Comment
## out the qsub and test one to make sure it works before you submit
## all the jobs

## Change your file extension to match what you have.
for f in *.filter.clean.merged.fq.gz; do
READCOUNT=$(gunzip -c ${f} | wc -l | awk '{d=$1; print d/4;}')
g=$(basename $f .filter.clean.merged.fq.gz)

echo "
#!/bin/bash
#$ -N fungal.${g}
#$ -q bio,abio*,free*,pub*
#$ -R y
#$ -pe openmp 4
#$ -ckpt restart

## Load in the necessary modules
module load blast
module load enthought_python

## Move into the folder with the metagenomes
cd $BASEDIR

## Unzip the metagenomes and make them into fasta sequences (from fq)
gunzip -c ${f} | fastq-to-fasta.py -o ${WORKDIR}${g}.fasta -

## The blast part:
blastn -query ${WORKDIR}${g}.fasta \
-task megablast \
-db $BLAST_DB \
-outfmt '6 std staxids sskingdoms salltitles stitle' \
-max_hsps 1 \
-max_target_seqs 1 \
-num_threads 4 \
-out ${WORKDIR}${g}.blast.txt

cd ${WORKDIR}
## Clean up! Remove the temp fasta
rm ${g}.fasta

## havent tested this out yet:
## Filters the blast results to weed out bad alignments
awk -F '\t' '{if (\$3>=90 && \$4 >65 && \$12>100)print \$0 }' ${WORKDIR}${g}.blast.txt > ${WORKDIR}${g}.blast.filter.txt

awk '{print \$16, \$17}' OFS='_' ${g}.blast.filter.txt | sed 's/[^a-zA-Z0-9_]//g' | sort | uniq -c > ${g}.fungal.counts
while read line; do echo ${READCOUNT} ${g}; done < ${g}.fungal.counts > ${g}.tmp
paste ${g}.fungal.counts ${g}.tmp | tr -s ' ' > ${g}.fungal.final

## Clean up! Remove temp outs
rm ${g}.fungal.counts
rm ${g}.tmp

## Get rid of the error file that has this weird error over and over:
## Taxonomy name lookup from taxid requires installation of taxdb database with ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
## Not super necessary
rm ../${g}.fungal.e*
" > ${WORKDIR}${g}.fungal.sh
echo "Submitting job ${counter} out of ${total_files} "

counter=$((counter+1))

qsub ${WORKDIR}sample_${g}.fungal.sh

done
