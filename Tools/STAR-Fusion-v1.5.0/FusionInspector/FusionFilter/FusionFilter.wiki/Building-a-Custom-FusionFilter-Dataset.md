# Building a Custom FusionFilter Dataset

To build a custom FusionFilter dataset, you require a genome in FASTA format (eg. 'genome.fa') and a gene annotation set in GTF format (eg. transcripts.GTF). 

You will also need the following tools installed and available via your PATH setting.

* [STAR aligner](https://github.com/alexdobin/STAR/releases)
* [ncbi blast+] (ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)
* [hmmer3](http://hmmer.org/)

And download the [Pfam-A.hmm](ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz) database, and prepare it for Pfam searches with hmmer:

     Building the Pfam-A database involves the following.
     % gunzip Pfam-A.hmm.gz
     % hmmpress Pfam-A.hmm


After having the above tools and database installed, the steps to build a CTAT genome lib include:

1.  (Optional) Remove any transcripts from your transcripts.GTF file that you do not want included as candidate fusion targets.  

2.  Run the CTAT genome builder like so:

    ${FUSION_FILTER_HOME}/prep_genome_lib.pl \
          --genome_fa genome.fa \
          --gtf transcripts.gtf \
          --pfam_db /path/to/Pfam-A.hmm \
          --CPU 10  # number of threads 

          (and optionally) 
         --fusion_annot_lib /path/to/file/containing/fusion_annotations.txt  # see below

Executing the above will generate and populate the CTAT genome lib, by default called 'ctat_genome_lib_build_dir' in your current working directory.  See the additional options available to prep_genome_lib.pl above for further customization.


## Optional, include Fusion annotations

If you would like to include annotations for known fusions, create a file containing the format:

     geneA--geneB(tab)some annotation text that describes this fusion
     ...

and you can also include individual gene annotations like so:

     geneA(tab)any annotation I want to include for this gene symbol
     ...


For example:
```
    ATIC--ALK       Cosmic{samples=99,mutations=12,papers=20},chimerdb_pubmed{Anaplastic large cell lymphoma (ALCL),Inflammatory myofibroblastic tumour}
    ATL2--HNRPLL    YOSHIHARA_TCGA_num_samples[BRCA:1|LUAD:1],{Klijn_CCL:Lung=1}
    ATM     ATM_serine/threonine_kinase,ArcherDX_panel,FoundationOne_panel
    ATL1    atlastin_GTPase_1
    ATL2    atlastin_GTPase_2
    ATL3    atlastin_GTPase_3
```


In case you're curious about any data formatting issues or required contents, please see examples for data sets we provide source data files and fully built CTAT genome libs at <https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/>