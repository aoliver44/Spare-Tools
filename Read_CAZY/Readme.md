## Read-based CAZY identification

This script is designed to identify Glycoside hydrolases and polysaccharide lyases (GH and PLs...it can also idenitfy everything if you make a small tweak) in shotgun metagenomic reads. Some caveats:

- you need other programs, specifically
	* conda installation of rundbcan (named rundbcan)
	* conda installation of microbecensus (named microbecensus)
	* prodigal
	* bbmap
	* R/3.6.2 with tidyverse
	* All of this is on the UCI HPC3
- This only uses HMM...so it does an OK job identifing conserved domains of CAZys.
	* in my brief look, it slightly over estimates based on HMM on things that assemble WELL (something like 49/43 in sample data). But underestimates slightly more when you use more than 1 tool to identify CAZymes (something like 49/70 identified). 
	* I dont think there is a perfect answer, as long as you are doing the same thing to all the samples.
- The script will run on the example data right now, modify it to run on your data!
	* read the script to see those places to change (repair.sh section, sample_list.txt section, BASDIR/WORKDIR sections, SLURM parameters, etc.)

### To download & sample data:
(assuming you have the conda installations & R-3.6.2/Tidyverse)
```
git clone https://github.com/aoliver44/Spare-Tools.git
cd Spare-Tools/Read_CAZY
chmod +x preprocess.sh
bash read_cazy.sh
```

# Lots of information in the read_cazy.sh script!! 

```
## Youll need to install a few pkgs via conda:
########## DBCAN ############
# Github: https://github.com/linnabrown/run_dbcan
module load anaconda
conda create -n run_dbcan python=3.8 diamond hmmer prodigal -c conda-forge -c bioconda
conda activate run_dbcan
pip install run-dbcan==2.0.11
test -d db || mkdir db
cd db \
    && wget http://bcb.unl.edu/dbCAN2/download/CAZyDB.07312019.fa.nr && diamond makedb --in CAZyDB.07312019.fa.nr -d CAZy \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/dbCAN-HMMdb-V8.txt && mv dbCAN-HMMdb-V8.txt dbCAN.txt && hmmpress dbCAN.txt \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/tcdb.fa && diamond makedb --in tcdb.fa -d tcdb \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/tf-1.hmm && hmmpress tf-1.hmm \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/tf-2.hmm && hmmpress tf-2.hmm \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/stp.hmm && hmmpress stp.hmm \
    && cd ../ && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.fna \
    && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.faa \
    && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.gff

conda deactivate
########## Microbecensus ############
# Github: https://github.com/snayfach/MicrobeCensus
module load anaconda
conda create -n microbecensus
conda activate microbecensus
conda install -c bioconda microbecensus
conda deactivate

```