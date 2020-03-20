#!/bin/bash

## Cat all the fungal counts together and count unique hits per species
cat *.fungal.final >> Fungal_counts.txt
sort -k3,3nr Fungal_counts.txt | uniq > tmp1.txt
MAX_READS=$(awk '{print $3}' tmp1.txt | head -1)

## Add a line for the normalization factor
while read count species reads metagenome; do 
echo "scale=4 ; $reads / $MAX_READS" | bc; done < tmp1.txt > tmp2.txt
paste -d' ' tmp1.txt tmp2.txt > tmp3.txt

## Multiply normalization factor by fungal counts
while read count species reads metagenome norm; do
echo "scale=4 ; $norm * $count" | bc; done < tmp3.txt > tmp4.txt
paste -d' ' tmp3.txt tmp4.txt > tmp5.txt

## Add norm fungal counts to fungal counts
while read count species reads metagenome norm add; do
echo "scale=4 ; $add + $count" | bc; done < tmp5.txt > tmp6.txt
paste -d' ' tmp5.txt tmp6.txt | awk -F'[ ]' '{print $4, $3, $7}' OFS='\t' > Fungal_results.txt
rm tmp*.txt
