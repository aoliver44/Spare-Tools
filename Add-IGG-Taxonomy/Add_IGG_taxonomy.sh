#!/bin/bash

# What you NEED (my script will attempt to download from internet):
##### A total_mapped_reads.tsv file from IGGoutput
##### the iggdb_v1.0.0.species from MIDAS db
##### R(tested with v3.5.1, may work with others)
########## libraries tidyverse and janitor

STARTTIME=$(date +%s)

echo "
###########################################################
                ___  __  __
  /\   _|  _|    |  /__ /__
 /--\ (_| (_|   _|_ \_| \_|
 ___
  |  _.     _  ._   _  ._ _
  | (_| >< (_) | | (_) | | | \/
                             /
###########################################################
"
# font from: http://patorjk.com/software/taag/#p=display&f=Graffiti&t=Type%20Something%20
# font style: mini

echo "checking if input and database files exist..."
sleep 2
# check for iggdb_v1.0.0.species file
if [ -f iggdb_v1.0.0.species ]; then
    echo "iggdb_v1.0.0.species exist, wont download again"
else
    echo "iggdb_v1.0.0.species doesn't exist. I'll get that for you"
    wget http://hpc.oit.uci.edu/~aoliver2/iggdb_v1.0.0.species
fi

if [ ! -f total_mapped_reads.tsv ]; then
    echo "Igg merged output not found."
    exit 0
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
igg_raw <- t(read.csv('total_mapped_reads.tsv', sep = '\t', row.names = 1, check.names = F));
species_db <- read.csv('iggdb_v1.0.0.species', sep = '\t', check.names = F, header = T);
species_db <- species_db %>% select(., species_id, species_name, gtdb_taxonomy);
igg_merged <- merge(species_db, igg_raw, by.x = 'species_id', by.y = 'row.names');

# Clean up merged db and species
# Change where it spilts in seperate from \\| to ; if needed
igg_merged <- igg_merged %>%
  separate(., col = gtdb_taxonomy, into = c('kingdom','phylum','class','order','family','genus','species'),
           sep = ';', remove = T, extra = 'drop');
igg_merged\$clean_species <- paste0(igg_merged\$species_name,'_',igg_merged\$species_id);
igg_merged\$clean_species <- make_clean_names(igg_merged\$clean_species);

# select what you care about and output file
igg_final <- igg_merged %>% select(., 'kingdom':'species', clean_species, colnames(igg_raw));
write_delim(x = igg_final, path = 'count_reads_taxonomy.tsv', delim = '\t', col_names = T);
" | R --vanilla --no-save

ENDTIME=$(date +%s)

echo "Done! Finished in $(($ENDTIME - $STARTTIME)) seconds."