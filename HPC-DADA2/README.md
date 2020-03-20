## Scripts for processing Amplicon data on the UCI HPC

**The bulk of this is just DADA2**

1. Please have your files in a folder on the HPC called raw_data/

2. The files should be named

* forward.fastq.gz
* reverse.fastq.gz
* barcodes.fastq.gz

3. Outside of raw_data/ you should have a file called metadata.tsv that you would use in Qiime2 to demultiplex

4. You should have a successful R/3.5 environment on the HPC with DADA2 installed

5. Run import_qc.sh using qsub

6. Examine the QC plots and change the filtering parameters in the denoise script

7. Run the denoise script. Make sure you have taxonomy downloaded where you want it to. Here is a helpful link:

* [Dada2 taxonomy profilers]https://benjjneb.github.io/dada2/training.html

Examples of how i run it:

(in a dir outside of raw_data/ with metadata.tsv in it)

```
qsub import_qc.sh
```

next 

``` 
cd demultiplexed_seqs/*/data/ 
qsub Dada_Denoise.sh
```