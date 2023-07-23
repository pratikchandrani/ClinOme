
## Which version of STAR is compatible with which version of STAR-Fusion?

It can be confusing as to which versions are compatible with the different software.   Because everything's been fairly dynamic, we try to support only the latest version of STAR-Fusion, which should ideally be compatible with the latest version of STAR.

We do, however, have Docker images for each of the major releases, which come bundled with the targeted version of the STAR aligner.  You can grab these from here:
https://hub.docker.com/r/trinityctat/ctatfusion/tags/

and the Docker file itself is under version control:
https://github.com/STAR-Fusion/STAR-Fusion/blob/master/Docker/Dockerfile

The CTAT genome libs that correspond to the different release fall into 2 categories right now:  < STAR-Fusion v1.3 and >= STAR-Fusion v1.3:
https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/

Versions of STAR-Fusion starting at v1.4.0 check for the version of the STAR being used and will indicate if the version is out of date, failing to be compatible.