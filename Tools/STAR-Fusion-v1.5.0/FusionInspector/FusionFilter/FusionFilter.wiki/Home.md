# FusionFilter

FusionFilter provides a common fusion-finding, filtering, and annotation framework used by the [Trinity Cancer Transcriptome Analysis Toolkit (CTAT)](https://github.com/NCIP/Trinity_CTAT/wiki).  This system is leveraged for preparing a target genome and annotation set for fusion transcript identification, fusion feature annotation, and integrates utilities for filtering likely false-positive fusions.  The genome resource building process creates a 'CTAT genome resource library'.  Inputs required by FusionFilter for building a human genome resource library, in addition to pre-compiled CTAT human genome resource libs, are made available at <https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/>.  See below if you want to create your own CTAT genome resource lib for human or for other organism or genome targets.

FusionFilter is integrated as a submodule of CTAT fusion detection tools including: [STAR-Fusion](http://star-fusion.github.io), [DISCASM/GMAP-fusion](https://github.com/DISCASM/DISCASM/wiki), and [FusionInspector](https://github.com/FusionInspector/FusionInspector/wiki).

While the initial use of FusionFilter is to build the genome and annotation resource sets required by CTAT tools for fusion finding, it is leveraged by CTAT tools for final filtering of likely false positives according to the following criteria:

*  the two partners of a candidate fusion transcript share sequence similarity as determined by a BLAST search.
*  one of the fusion partners is considered promiscuous in that it shows up as having multiple candidate fusion parters.

## Installing FusionFilter

FusionFilter is already included as a submodule within each of the Trinity CTAT Fusion resources.  If you would like to install it separately, you can download [FusionFilter from the GitHub Release portal](https://github.com/FusionFilter/FusionFilter/releases).


Data resources required for CTAT fusion transcript discovery in human RNA-Seq cancer samples is readily available at
<https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/>, which includes the human genome, Gencode annotations, reference cDNA sequences, and coding annotations in gtf format.  Also included are precomputed BLAST+ results from an all-vs-all search of the transcript sequences, Pfam domains identified in human protein sequences, and human cancer fusion annotations, which we compile from multiple sources <https://github.com/FusionAnnotator/CTAT_HumanFusionLib/releases>.

Alignment utilities used by Trinity CTAT include [STAR](https://github.com/alexdobin/STAR) (as used by **STAR-Fusion** and **FusionInspector**), and [GMAP](http://research-pub.gene.com/gmap/) as used in (**GMAP-fusion** in the **DISCASM/GMAP-fusion** process).  Be sure to have each installed and available for use via your PATH setting.

Then, unpack the data resources and index the resources like so:

     tar xvf CTAT_resource_lib.tar.gz


>Download a pre-compiled CTAT genome lib, if possible.  The download is larger and takes long, but it includes all processed data and saves you from having to run through the build process below.

If you download a 'data source' build, then you need to execute the genome lib build process like so:

     %  cd CTAT_resource_lib/

     %  ${FusionFilter_HOME}/prep_genome_lib.pl \
                         --genome_fa ref_genome.fa \
                         --gtf ref_annot.gtf \
                         --fusion_annot_lib CTAT_HumanFusionLib.dat.gz \
                         --annot_filter_rule AnnotFilterRule.pm \
                         --pfam_db Pfam-A.hmm

>Note, the Pfam results are already compiled for you in the source build. Just putting Pfam-A.hmm as the parameter value (even if it's not there) will trigger the system to just use the existing results.  Also, pre-computed blast results are provided in the source data lib, which will also just be used by the system automatically.  If you were building your own custom data lib (see bottom of page for info), the system would run pfam and blast to generate the required results.

Once the build is complete, you then refer to the above resource directory via the '--genome_lib_dir' parameter of the CTAT utility to be executed, or set the path to an environmental variable 'CTAT_GENOME_LIB' to be conveniently auto-recognized among CTAT tools (where indicated as available).

## Building a Custom Genome Resource Library for Fusion Detection
>If you want to build a resource data set for another genome or different corresponding reference annotation set, see our documentation on [Building a Custom FusionFilter Dataset](Building-a-Custom-FusionFilter-Dataset).

## User support

Contact us on our google group <https://groups.google.com/forum/#!forum/trinity_ctat_users>