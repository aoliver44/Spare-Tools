### Read-based CAZY identification

This script is designed to identify Glycoside hydrolases and polysaccharide lyases (GH and PLs...it can also idenitfy everything if you make a small tweak) in shotgun metagenomic reads. Some caveats:

- you need other programs, specifically
	* conda installation of rundbcan
	* conda installation of microbecensus
	* prodigal
	* bbmap
	* R/3.6.2 with tidyverse
	* All of this is on the UCI HPC3
- This only uses HMM...so it does an OK job identifing conserved domains of CAZys.
	* in my brief look, it ~slightly~ over estimates based on HMM on things that assemble WELL (something like 49/43). But underestimates ~slightly more~ when you use more than 1 tool to identify CAZymes (something like 49/70 identified). 
	* I dont think there is a perfect answer, as long as you are doing the same thing to all the samples.
- The script will run on the example data right now, modify it to run on your data!
	* read the script to see those places to change (repair.sh section, sample_list.txt section, BASDIR/WORKDIR sections, SLURM parameters, etc.)

## To download & sample data:
(assuming you have the conda installations & R-3.6.2/Tidyverse)
```
git clone https://github.com/aoliver44/Spare-Tools.git
cd Spare-Tools/Read_CAZY
chmod +x preprocess.sh
bash read_cazy.sh
```

# Lots of information in the read_cazy.sh script!! 

