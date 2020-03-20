#!/bin/bash

# What you NEED (my script will attempt to download from internet):
##### A total_mapped_reads.tsv file from IGGoutput
##### the iggdb_v1.0.0.species from MIDAS db

# NOTE: this runs ~20 seconds faster if you use ag instead of grep

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

echo "checking if database files exist..."
sleep 2
# check for iggdb_v1.0.0.species file
if [ -f iggdb_v1.0.0.species ]; then
    echo "iggdb_v1.0.0.species exist, wont download again"
else 
    echo "iggdb_v1.0.0.species doesn't exist. I'll get that for you"
    wget http://hpc.oit.uci.edu/~aoliver2/iggdb_v1.0.0.species
fi


echo "
############################################
running...


"
# transpose the total_mapped_reads.tsv file:
awk '
{
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' total_mapped_reads.tsv | tr ' ' \\t > mapped_reads.txt
# this is to determine the read counts...MIDAS looks for everything
# and you dont care about the organisms that didnt show up in your
# data
awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }' mapped_reads.txt > row_counts.txt
paste -d'\t' row_counts.txt mapped_reads.txt > tmp0.txt

# this is where you separate out the species names that had
# greater than 0 counts so you can search the MIDAS DB for. Also
# im making a subsetted OTU - like matrix to merge on later
sort -k1,1nr tmp0.txt | awk -F '[\t]' '{if ($1>=1)print $2}' > tmp.txt
sort -k1,1nr tmp0.txt | awk -F '[\t]' '{if ($1>=1)print $0}' | cut -f2- > count_reads_tmp.txt
head -1 mapped_reads.txt | cat - count_reads_tmp.txt > count_reads_clean.txt

# Get the OTU-IDs
grep OTU total_mapped_reads.tsv | sed "s/\t/\n/g" | tail -n +2 > tmp1.txt

# Take the genome IDs and get the higher level taxa info
while read line; do grep -m 1 ${line} iggdb_v1.0.0.species | awk -F '[\t;]' '{print $10"\t"$11"\t"$12"\t"$13"\t"$14"\t"$15"\t"$3}'; done < tmp1.txt > tmp2.txt
echo -e "kingdom\tphylum\tclass\torder\tfamily\tgenus\tspecies" | cat - tmp2.txt > tmp3.txt

# Paste together the taxonomy and the new OTU without all the 0s
paste -d"\t" tmp3.txt count_reads_clean.txt > count_reads_taxonomy.txt


# Clean up!
rm tmp.txt
rm tmp0.txt
rm tmp1.txt
rm tmp2.txt
rm tmp3.txt
rm row_counts.txt
rm count_reads_clean.txt
rm count_reads_tmp.txt

ENDTIME=$(date +%s)

echo "Done! Finished in $(($ENDTIME - $STARTTIME)) seconds."


