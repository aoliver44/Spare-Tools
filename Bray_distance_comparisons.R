#######################################
#### comparisons of bray distances ####
#######################################

library(tidyverse)
library(vegan)
library(ggpubr)
library(ggplot2)
library(reshape2)

merge_meta <- merge(metadata, midas, by.x = "merge_name", by.y = "row.names") 
rownames(merge_meta) <- merge_meta$merge_name
pre_distance_OTU <- merge_meta %>% select(., 10:NCOL(merge_meta))

bray_dist <- vegdist(pre_distance_OTU, method = "bray")

# match up the order of the metadata based on the distance matrix
metadata_ordered <- metadata[match(rownames(as.data.frame(as.matrix(bray_dist))), metadata$merge_name), ]

# take mean distances based on individual
ind_bcs <- meandist(bray_dist, grouping = metadata_ordered$household)
# get the diagonal of the matrix...basically the avg within an factor
within_bcs <- as.data.frame(diag(as.matrix(ind_bcs)))

# calculate the between BC distances
tmp_diag <- ind_bcs
diag(tmp_diag) <- NA
tmp_diag <- as.data.frame(as.matrix(tmp_diag))
tmp_melt <- melt(tmp_diag)

between_bcs <- tmp_melt %>% group_by(., variable) %>% drop_na(.) %>% summarise(., mean = mean(value))

# Group within and between together and merge with metadata

bc_distances <- merge(within_bcs, between_bcs, by.x = "row.names", by.y = "variable")
bc_distances <- bc_distances %>% drop_na(.)
colnames(bc_distances) <- c("factor", "within", "between")
bc_distances_melted <- melt(bc_distances, id.vars = "factor")

ggplot(data = bc_distances_melted) +
  aes(x = variable, y = value, fill = variable) +
  geom_boxplot(outlier.shape = NA) + geom_jitter(width = 0.15) +
  theme_classic((base_size = 14)) + ggtitle("Neighbor poops are different than family poops: KMER EDITION", subtitle = "By household (n = 22)") + 
  xlab("") + ylab("Bray Curtis Dissimilarity") + 
  scale_fill_manual(values=c("grey69", "tomato3")) + 
  stat_compare_means(method = "t.test", label.x.npc = .4) 
