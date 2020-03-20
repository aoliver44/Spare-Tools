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
    wget http://hpc.oit.uci.edu/~aoliver2/genome_info.txt
fi

# check for genome_taxonomy.txt file
if [ -f genome_taxonomy.txt ]; then
    echo "genome_taxonomy.txt exist, wont download again"
else
    echo "genome_taxonomy.txt doesn't exist. I'll get that for you"
    wget http://hpc.oit.uci.edu/~aoliver2/genome_taxonomy.txt
fi

echo "
############################################
running...


"

# this is to determine the read counts...MIDAS looks for everything
# and you dont care about the organisms that didnt show up in your
# data
awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }' count_reads.txt > row_counts.txt
paste -d'\t' row_counts.txt count_reads.txt > tmp0.txt

# this is where you separate out the species names that had
# greater than 0 counts so you can search the MIDAS DB for. Also
# im making a subsetted OTU - like matrix to merge on later
sort -k1,1nr tmp0.txt | awk -F '[\t]' '{if ($1>=1)print $2}' > tmp.txt
sort -k1,1nr tmp0.txt | awk -F '[\t]' '{if ($1>=1)print $0}' | cut -f2- > count_reads_tmp.txt
head -1 count_reads.txt | cat - count_reads_tmp.txt | cut - -f1 --complement > count_reads_clean.txt

# Take the species and get the genome IDs
while read line; do grep -m 1 ${line} genome_info.txt | awk '{print $1}'; done < tmp.txt > tmp1.txt

# Take the genome IDs and get the higher level taxa info
while read line; do grep -m 1 ${line} genome_taxonomy.txt | awk -F '[\t]' '{print "d_"$4"|p_"$5"|c_"$6"|o_"$7"|f_"$8"|g_"$9"|s_"$10"_"$1}'; done < tmp1.txt | sed "s/ /_/g" > tmp2.txt
echo -e "kingdom|phylum|class|order|family|genus|species" | cat - tmp2.txt > tmp3.txt

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