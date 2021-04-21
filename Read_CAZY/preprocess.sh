#!/bin/bash

###########################################
#   Combine normalization and CAZY
##########################################

module purge
module load R/3.6.2

sample=$1

echo "
library(dplyr);
library(stringr);

microbe_census_params <- read.csv(paste0('${sample}', '.mc_out'), sep='\t', stringsAsFactors=F)
microbe_census_params2 <- droplevels(microbe_census_params);
norm_factor <- as.numeric(microbe_census_params2[11,1]);

hmm_results <- read.csv(paste0('${sample}', '.hmm_parsed'), sep='\t', stringsAsFactors=F, header=F);
hmm_grouped <- hmm_results %>% group_by(., V3,V4) %>% count()

hmm_grouped\$norm_factor <- norm_factor
hmm_grouped\$normalized_counts <- (hmm_grouped\$n / hmm_grouped\$V4) / hmm_grouped\$norm_factor

hmm_normalized_table <- hmm_grouped %>% dplyr::select(., V3, normalized_counts) %>% filter(str_detect(V3, 'GH|PL')) %>% group_by(., V3) %>% summarise(., sum = sum(normalized_counts));
write.table(x = hmm_normalized_table, file = paste0('${sample}', '.norm_cazy.txt'), quote=F, sep='\t')

" | R --vanilla --no-save

# clean up R output a little more bc im better at some stuff in bash
tail -n+2 ${sample}.norm_cazy.txt | sed 's/.hmm//g' | cut -f2,3 > ${sample}.norm_cazy_1.txt
printf "Enzyme\t${sample}\n" | cat - ${sample}.norm_cazy_1.txt > ${sample}.cazy.txt

###########################################
#   Clean Up!
##########################################


rm ${sample}.norm_cazy.txt
rm ${sample}.norm_cazy_1.txt
rm ${sample}.hmm_parsed.*
