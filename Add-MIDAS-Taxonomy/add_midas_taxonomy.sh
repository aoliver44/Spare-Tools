#!/bin/bash

# What you NEED (my script will attempt to download from internet):
##### A count_reads.txt file from MIDAS output
##### the genome_info.txt from MIDAS db
##### the genome_taxonomy.txt from MIDAS db

# NOTE: this runs ~20 seconds faster if you use ag instead of grep

STARTTIME=$(date +%s)

echo "
###########################################################
                     ___  _        __
  /\   _|  _|   |\/|  |  | \  /\  (_
 /--\ (_| (_|   |  | _|_ |_/ /--\ __)
 ___
  |  _.     _  ._   _  ._ _
  | (_| >< (_) | | (_) | | | \/
                             /
###########################################################
"
# font from: http://patorjk.com/software/taag/#p=display&f=Graffiti&t=Type%20Something%20
# font style: mini

echo "checking if database files exist..."
sleep 2
# check for genome_info.txt file
if [ -f genome_info.txt ]; then
    echo "genome_info.txt exist, wont download again"
else
    echo "genome_info.txt doesn't exist. I'll get that for you"
    cp /dfs6/commondata/midas_db_v1.2/genome_info.txt .
fi

# check for genome_taxonomy.txt file
if [ -f genome_taxonomy.txt ]; then
    echo "genome_taxonomy.txt exist, wont download again"
else
    echo "genome_taxonomy.txt doesn't exist. I'll get that for you"
    cp  /dfs6/commondata/midas_db_v1.2/genome_taxonomy.txt .
fi

echo "
############################################
running...


"
module load R/3.5.1
echo "
library(tidyverse);
library(janitor);

# Read in files
raw <- read.csv('count_reads.txt', sep = '\t', row.names = 1, check.names = F);

genome_info <- read.csv('genome_info.txt', sep = '\t', check.names = F, header = T);
genome_info <- genome_info %>% select(., genome_id, species_id);
genome_tax <- read.csv('genome_taxonomy.txt', sep = '\t', check.names = F, header = T);
genome_tax <- genome_tax %>% select(., genome_id, kingdom, phylum, class, order, family, genus, species);
all_genome_info <- merge(genome_info, genome_tax, by.x = 'genome_id', by.y = 'genome_id');
all_genome_info <- all_genome_info %>% 
  filter(., kingdom != '') %>% 
  filter(., phylum != '') %>% 
  filter(., class != '') %>%
  filter(., order != '') %>% 
  filter(., family != '') %>%
  filter(., genus != '') %>% droplevels();
                                              
all_genome_info <- all_genome_info[!duplicated(all_genome_info\$species_id),];

midas_phylogeny <- merge(all_genome_info, raw, by.x = 'species_id', by.y = 'row.names');

midas_phylogeny\$sum <- rowSums(midas_phylogeny[10:NCOL(midas_phylogeny)]);
midas_phylogeny <- midas_phylogeny %>% filter(., sum > 0) %>% select(., -species_id, -sum, -genome_id);

write_delim(x = midas_phylogeny, path = 'count_reads_tax.midas.tsv', delim = '\t', col_names = T);

" | R --vanilla --no-save 

ENDTIME=$(date +%s)

echo "Done! Finished in $(($ENDTIME - $STARTTIME)) seconds."