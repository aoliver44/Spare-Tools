###################################
########## Taxa Barplots ##########
###################################

# load libraries
library(readxl)
library(ggplot2)
library(reshape2)
library(cowplot)
library(tidyverse)

# set working directory & load files
setwd("~/Google Drive File Stream/My Drive/Other/Sarah_Steele/")
set.seed(999)

# Sequence Data: read in sequence data so that samples are in the first column,
# and all other columns are the taxa
midas <- as.data.frame(t(read.csv("Bacteria_Composition_Summary.txt", 
                                  check.names = FALSE, sep = "\t", 
                                  row.names = 1, header = F)))

# Metadata if you have it!
metadata <- read.csv("Final_Mapping_File for microbiomeanalyst.txt", 
                     sep = "\t", header = T)


## The competition to stephens Taxonomy Solution

# Split taxonomy into different sections L1-L7
# Change where it spilts in seperate from | to ; if needed
midas_melt <- melt(midas, id.vars = "Taxa") %>% 
  rename(., Subject_ID = Taxa) %>% 
  separate(., col = variable, into = c("L1","L2","L3","L4","L5","L6","L7"), sep = "\\|", remove = T, extra = "drop")

# Make sure the rel abundance or counts are numeric
midas_melt$value <- as.numeric(midas_melt$value)

# Add in the metadata, make sure you merge on the correct columns!
midas_melt <- merge(metadata, midas_melt, by.x = "X.NAME", by.y = "Subject_ID")

# Summarize by L6 genus (or any other taxa group)...
# if you change make sure you change L6 and prefix (^g_)
# this is also grabbing the top 11 taxa
midas_summarize <- midas_melt %>% 
  group_by(., L6) %>% 
  filter(str_detect(L6, "^g_")) %>% 
  summarise(., top_bacteria = sum(value)) %>% 
  arrange(., desc(top_bacteria)) %>% slice(., 1:11)

# group the main players (top 11) together into a list
high_abundance <- split(midas_summarize$L6, 1:NROW(midas_summarize))

# change everything that is not a main player into a other catagory
midas_melt$L6[midas_melt$L6 %in% high_abundance != "TRUE"] <- "other"

# nice color schemes!
stephen_12 <- c('#a6cee3','#1f78b4','#b2df8a','#33a02c','#fb9a99','#e31a1c','#fdbf6f','#ff7f00','#cab2d6','#6a3d9a','#ffff99','#b15928')

sarah_color <- c("#7F0A57", "#A64685", "#CD9ABB", "#0B447A", "#3F77AC", "#4176AA", "#74A9DD", "#007976", "#39A9AB", "#71CFC5", "#72D3C6", "#007947", "#3BAA78")

julio_color <- c("#003f5c", "#2f4b7c", "#665191", "#a05195", "#d45087", "#f95d6a", "#ff7c43", "#ffa600", "#7f0a57", "#cd9abb", "#39a9ab", "#71cfc5", "#007947", "#bebebe")
# Plot

ggplot(data = subset(midas_melt), 
       aes(x = as.factor(Timepoint), weight = value, fill = L6)) +
  geom_bar(position = position_fill()) +
  theme_bw(base_size = 16) + 
  facet_grid(. ~  Individual, space = "free", scales = "free") + 
  scale_fill_manual(values = julio_color) +
  theme(panel.spacing = unit(0.1, "lines")) +   
  theme(axis.ticks.x=element_blank()) +
  labs(x = '',
       y = 'Relative Abundance') + theme(legend.position = "none") +
  ggtitle("Taxa Barplot") +
  scale_y_continuous(labels = scales::percent_format()) +
  theme(plot.title = element_text(hjust = 0.5), plot.margin = unit(c(0.5, 0, 0.5, 0.5), "cm"))
