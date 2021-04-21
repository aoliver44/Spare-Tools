#!/bin/bash

###########################################
#   Useful Information
##########################################

## Script for taking metagenomic data and blasting against
## the GH (CAzy) database
## Thanks for some script ideas Alex Chase

## Youll need to install a few pkgs via conda:
########## DBCAN ############
# Github: https://github.com/linnabrown/run_dbcan
# conda create -n run_dbcan python=3.8 diamond hmmer prodigal -c conda-forge -c bioconda
# conda activate run_dbcan
# pip install run-dbcan==2.0.11
# test -d db || mkdir db
# cd db \
#     && wget http://bcb.unl.edu/dbCAN2/download/CAZyDB.07312019.fa.nr && diamond makedb --in CAZyDB.07312019.fa.nr -d CAZy \
#     && wget http://bcb.unl.edu/dbCAN2/download/Databases/dbCAN-HMMdb-V8.txt && mv dbCAN-HMMdb-V8.txt dbCAN.txt && hmmpress dbCAN.txt \
#     && wget http://bcb.unl.edu/dbCAN2/download/Databases/tcdb.fa && diamond makedb --in tcdb.fa -d tcdb \
#     && wget http://bcb.unl.edu/dbCAN2/download/Databases/tf-1.hmm && hmmpress tf-1.hmm \
#     && wget http://bcb.unl.edu/dbCAN2/download/Databases/tf-2.hmm && hmmpress tf-2.hmm \
#     && wget http://bcb.unl.edu/dbCAN2/download/Databases/stp.hmm && hmmpress stp.hmm \
#     && cd ../ && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.fna \
#     && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.faa \
#     && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.gff

########## Microbecensus ############
# Github: https://github.com/snayfach/MicrobeCensus
# conda install -c bioconda microbecensus


###########################################
#   BEGIN
##########################################


# define some environmental variables:
# path to reads
BASEDIR=/dfs5/bio/aoliver2/chicha/microbiome_comparisons/read_cazy_test/
# path to HMM database, called dbCAN.txt
DBCAN_DB=/dfs3b/whitesonlab/CAZy_dbs/dbCAN.txt
# where you want the outfiles written
WORKDIR=/dfs5/bio/aoliver2/chicha/microbiome_comparisons/read_cazy_test/output/

while read sample; do
echo "#!/bin/bash

#--------------------------SBATCH settings------

#SBATCH --job-name=${sample}_cazy      ## job name
##SBATCH -A **MYLAB**     ## account to charge
#SBATCH -p free          ## partition/queue name
#SBATCH --nodes=1            ## (-N) number of nodes to use
#SBATCH --ntasks=1           ## (-n) number of tasks to launch
#SBATCH --cpus-per-task=4    ## number of cores the job needs
##SBATCH --mail-user=**ME**@uci.edu ## your email address
##SBATCH --mail-type=begin,end,fail ##type of emails to receive
#SBATCH --error=${sample}-%J.err ## error log file
#SBATCH --output=${sample}-%J.out ##output info file

#--- If there is a doube hash (##) before SBATCH then it is deactivated---

##SBATCH --requeue
#Specifies that the job will be requeued after a node failure.
#The default is that the job will not be requeued.


#========Begin commands for job======

# load your starting modules
module load prodigal/2.6.3

cd ${BASEDIR}

# repair reads so that they are paired correctly
# NOTE: CHANGE THE in= and in2= TO MATCH YOUR 
# SAMPLE EXTENSION (ex. below .R1.fa and .R2.fa)
repair.sh in=${sample}.R1.fa.gz in2=${sample}.R2.fa.gz \
out=${WORKDIR}${sample}.clean.R1.fa out2=${WORKDIR}${sample}.clean.R2.fa

cd ${WORKDIR}

# merge the reads for better prodigal identification
bbmerge.sh in1=${sample}.clean.R1.fa in2=${sample}.clean.R2.fa \
out=${sample}.clean.merged.fa outu=${sample}.clean.unmerged.fa

# concatentate the reads together, 
# keeping merged and unmerged reads
cat ${sample}.clean.merged.fa ${sample}.clean.unmerged.fa \
> ${sample}.clean.total.fa

###########################################
#   Subsample to test 
##########################################

# uncomment to run subsampled reads, runs
# much faster using less data...duhhh
#reformat.sh in=${sample}.clean.total.fa out=${sample}.clean.total.subsample.fa samplereadstarget=200000
#mv ${sample}.clean.total.subsample.fa ${sample}.clean.total.fa

########################################


###########################################
#  PRODIGAL + HMMSCAN
##########################################

# predict ORFs
prodigal -i ${sample}.clean.total.fa \
-a ${sample}.faa -q \
-f gff -p meta > ${sample}.gff

# remove this huge file
rm ${sample}.gff

# search AAs against cazy using Hmmer and
# parameters set by dbCAN. I am using the
# dbcan anaconda installation just for their
# version of HMM...bc the HMM CAZy
# database was built with this version

module load anaconda
source activate run_dbcan
module purge

# This is how DBCAN runs HMMSCAN in their program
hmmsearch --domtblout ${sample}.hmm_out --cpu 4 -o /dev/null ${DBCAN_DB} ${sample}.faa

# This is DBCAN's HMM parser, which will parse the output
# for more stringent hits (youll need to chanage the python script to change these values):
# eval = 1e-15
# coverage = 0.35
hmmscan-parser.py ${sample}.hmm_out > ${sample}.hmm_parsed
conda deactivate


###########################################
#   Get Norm Factor - Microbecensus
##########################################
# great paper on this: 
# Average genome size estimation improves comparative metagenomics 
# and sheds light on the functional ecology of the human microbiome
# https://genomebiology.biomedcentral.com/articles/10.1186/s13059-015-0611-7

module load anaconda
source activate microbecensus
module purge

run_microbe_census.py -v -t 4 -n 1000000000 ${sample}.clean.total.fa ${sample}.mc_out

conda deactivate


###########################################
#   Combine normalization and CAZY
##########################################
# This will normalize the cazyme hits to the amount
# of genomes detected by microbecensus in your sample.

module purge
# make sure you have tidyverse installed in R!
module load R/3.6.2

mv ${BASEDIR}preprocess.sh ${WORKDIR}preprocess.sh
bash preprocess.sh ${sample}


###########################################
#   Clean Up!
##########################################


rm ${sample}.clean.R*
rm ${sample}.clean.mer*
rm ${sample}.clean.unmer*
#rm ${sample}.faa
#rm ${sample}.hmm*
#rm ${sample}.mc_out
rm ${sample}.norm_cazy.csv
rm ${sample}.norm_cazy_1.csv
cat ${sample}*.out ${sample}*.err > ${sample}.err.out
rm ${sample}*.out
rm ${sample}*.err

" > ${sample}_cazy.sh

# a list of fastq/a files without the extension. 
# ie. 
# sample1 NOT sample1.fastq
# sample2 NOT sample2.fastq
# sample3 NOT sample3.fastq
sbatch ${sample}_cazy.sh
done < sample_list.txt

###########################################
#  Afterwords, outside this script
##########################################

# in R youll want to make an "OTU" file of sorts
# for all the CAZyzmes. This is how to do that:
# in R:
# R > temp= list.files(pattern = "*.cazy.txt")
# R > myfiles = lapply(temp, read.delim)
# R > library(reshape2)
# R > library(tidyverse)
# R > otu <- myfiles %>% reduce(left_join, by = "Enzyme")
# R > write.table(otu, "tmp_cazy.txt", sep="\t", quote=F)
