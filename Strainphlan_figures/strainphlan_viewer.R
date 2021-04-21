#################################
######### Strain Figure #########
#################################

# load other libraries after optparse to not load them on help
library(ggplot2)
library(ggtree)
library(RColorBrewer)

# read newick tree
e.sir.tre <- read.tree( "~/Downloads/RAxML_bestTree.s__Bifidobacterium_adolescentis.StrainPhlAn3.tre" )
# create ggtree object
e.sir.gg <- ggtree( e.sir.tre ) 
# read in metadata file
e.sir.meta <- read.delim( file = "fiber_metadata.txt", sep = "\t" )
# add metadata to dendrogram plot
e.sir.gg <- e.sir.gg %<+% e.sir.meta
colors_inset <- c("#863636", "#8ad747", "#6e41c8", "#dbcb57", "#cb4bc0", "#6bd183", "#562d6f", "#839243", "#6f79cf", "#cf843b", "#8ab6d6", "#d74b34", "#8dceb6", "#d04a76", "#3c613a", "#ca8abe", "#37242f", "#d4aa97", "#56697f", "#785837")

# plot with color terminal edges and sample names with SubjectID and add tiplabels
png( args_list$args[4], width = 750, height = 300, res = 120 )
# strainphlan_tree_1.pdf
e.sir.gg_full <- e.sir.gg +  
  geom_tippoint( size = 3, aes( color = as.factor(Individual), shape = Intervention ) ) + 
  aes( branch.length = 'length' ) +
  theme_tree2() + theme(legend.position="right") + scale_color_manual(values = colors_inset)
temp <- dev.off()
# visualize tree with multiple sequence alignment (MSA)

# path to alignment file
e.sir.fasta <- ("~/Downloads/s__Eubacterium_rectale_aln.fasta")
# plot tree with slice of MSA
png( args_list$args[5], width = 750, height = 300, res = 120 )
# strainphlan_tree_2.pdf
msaplot( e.sir.gg + geom_tippoint( size = 3, aes(color = as.factor(Individual), shape = Intervention )), 
         e.sir.fasta, window = c(2415,2500), 
         color = brewer.pal(6, "Set3") ) + 
  theme( legend.position = 'right' )
temp <- dev.off()

###### Ordination ########
library(ape)
library(vegan)
library(ggplot2)
aa_align <- read.csv("~/Downloads/E_rectale_identities.matrix.csv", header = T, row.names = 1)
aa_align[is.na(aa_align)] <- 100
PatristicDistMatrix <- cophenetic(e.sir.tre)
tree_dist <- merge(e.sir.meta, PatristicDistMatrix, by.x = "Sample", by.y = "row.names")
drops <- c("GCA_000209935","GCA_001404855","GCA_001405295")
permanvoa_input <- tree_dist[ , !(names(tree_dist) %in% drops)]
# ordinate on the distance matrix
e.sir.pcoa <- cmdscale( PatristicDistMatrix, eig = T )

# variance explained 
variance <- head(eigenvals(e.sir.pcoa)/sum(eigenvals(e.sir.pcoa)))
x_variance <- as.integer(variance[1]*100)
y_variance <- as.integer(variance[2]*100)

# get scores for plotting
e.sir.scores <- as.data.frame( e.sir.pcoa$points )

# read in metadata file
# append to e.sir.scores
e.sir.scores.meta <- merge( e.sir.scores, e.sir.meta, by.x = 'row.names', by.y = "Sample")
# change colnames
colnames(e.sir.scores.meta)[2:3] <- c( "PCo1", "PCo2")

ggplot( e.sir.scores.meta, aes(PCo1, PCo2, color=as.factor(Individual), shape = Intervention) ) + 
  geom_point(size = 4, alpha = 0.75) + theme_classic() + 
  theme(axis.line.x = element_line(colour = 'black', size=0.75, linetype='solid'),
        axis.line.y = element_line(colour = 'black', size=0.75, linetype='solid'),
        axis.ticks = element_blank(), axis.text = element_blank()) + 
  xlab(paste("PCo1 (",x_variance,"% variance explained)")) + ylab(paste("PCo2 (",y_variance,"% variance explained)"))

adonis(formula = dist(permanvoa_input[5:NCOL(permanvoa_input)]) ~ as.factor(Individual) * Intervention, data = permanvoa_input)

