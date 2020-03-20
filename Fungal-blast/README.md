## Fungal-BLAST

By Andrew Oliver but mostly NCBI

v0.1.0

March 12, 2019

Fungal-Blast is a tool to blast short read data against a custom database of 12 fungal species that are popular in the gut, as decided by Matthew Gargus, a masters student in the Whiteson Lab who knows way more about fungi than i do.

It is easy to change the Blast DB to your choosing. Just change the variable in the script:

```{bash}
BLAST_DB=/data/users/mgargus/NCBI_fungal_genomes/fungal.fna
```
**Instructions for use:**

**1.** make sure your reads are in a folder with the scripts
necessary for this program.

**2.** change the script so it recogizes your file extension. In my example, they are called filter.clean.merged.fq.gz. To change them to match your script, you can use the basic sed command:

```{bash}
sed "s/.filter.clean.merged.fq.gz/[YOUR EXTENSION]/g" fungal-BLAST.sh > my-fungal-BLAST.sh
```

**3.** make sure the script is executable.

```{bash}
chmod +x fungal-BLAST.sh
```

**4.** run the script

```{bash}
bash fungal-BLAST.sh
```

**5.** After the script is done running, change directories into fungal_outs/ and then run the final script:

```{bash}
cd fungal_outs/
bash normalize_fungal_counts.sh
```

The final resulting file should have the normalized data you need to see if your short read data have a fungal presense. The file is missing headers, but the order of the data is (by column):

1. Metagenome ID

2. Species 

3. Total reads in metagenome

4. Normalized hits

**TROUBLESHOOTING:** If you're having a tough time, here is some practice data that might help get you started! This is a directory with all example data and scripts!

```{bash}
wget "http://hpc.oit.uci.edu/~aoliver2/example_data.tar.gz"
```
