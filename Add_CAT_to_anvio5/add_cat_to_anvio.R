## Add CAT/BAT annotations to anvio

# run (using anvio5): 
# anvi-export-table contigs.db --table genes_in_splits -o genes_in_splits.txt

setwd("~/Downloads/chicha_anvio5/")

library(tidyverse)

# read in anvio gene calls with contig info
anvio_gene_calls <- read.csv(file = "genes_in_splits.txt", sep = "\t", header = T)
anvio_gene_calls$contig_id <- sapply(strsplit(as.character(anvio_gene_calls$split), '_split'), `[`, 1)

# read in CAT taxa data
CAT_annotations <- read.csv(file = "classification_addnames.txt", sep = "\t", header = T)

# merge and select the cols anvio expects
anvio_taxa_table <- merge(anvio_gene_calls, CAT_annotations, by.x = "contig_id", by.y = "X..contig")
anvio_taxa_table <- anvio_taxa_table %>% select(., 4, 12:18)
names(anvio_taxa_table) <- c("gene_callers_id", "t_domain", "t_phylum", "t_class", "t_order", "t_family", "t_genus", "t_species")

write.table(x = anvio_taxa_table, file = "input_taxa_matrix.txt", quote = F, sep = '\t', row.names = F)
