#################################
######### Strain Figure #########
#################################

# load other libraries after optparse to not load them on help
library(ggplot2)
library(ggtree)
library(RColorBrewer)

# read newick tree
e.sir.tre <- read.tree( "~/Downloads/RAxML_bestTree.s__Eubacterium_rectale.StrainPhlAn3.tre" )
# create ggtree object
e.sir.gg <- ggtree( e.sir.tre )
# read in metadata file
e.sir.meta <- read.delim( args_list$args[2], header = T, sep = "\t" )
# add metadata to dendrogram plot
e.sir.gg <- e.sir.gg %<+% e.sir.meta

# plot with color terminal edges and sample names with SubjectID and add tiplabels
png( args_list$args[4], width = 750, height = 300, res = 120 )
# strainphlan_tree_1.pdf
e.sir.gg +  
  geom_tippoint( size = 3, aes( color = SubjectID ) ) + 
  aes( branch.length = 'length' ) +
  theme_tree2() + theme(legend.position="right")
temp <- dev.off()
# visualize tree with multiple sequence alignment (MSA)

# path to alignment file
e.sir.fasta <- ("~/Downloads/s__Eubacterium_rectale.StrainPhlAn3_concatenated.aln")
# plot tree with slice of MSA
png( args_list$args[5], width = 750, height = 300, res = 120 )
# strainphlan_tree_2.pdf
msaplot( e.sir.gg + geom_tippoint( size = 3), 
         e.sir.fasta, window = c( 490,540 ), 
         color = brewer.pal(6, "Set3") ) + 
  theme( legend.position = 'right' )
temp <- dev.off()
