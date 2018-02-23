Bootstrap: shub
From: akhanf/vasst-dev:v0.0.4d

#########
%setup
#########
mkdir $SINGULARITY_ROOTFS/diffparcellate
cp -Rv . $SINGULARITY_ROOTFS/diffparcellate

cp -v matlab/*.m $SINGULARITY_ROOTFS/opt/vasst-dev/tools/matlab
cp -v processBedpostParcellateSeedfromPrepDWI $SINGULARITY_ROOTFS/opt/vasst-dev/pipeline/dwi




%runscript
exec /diffparcellate/run.sh $@
