Bootstrap: shub
From: akhanf/vasst-dev:v0.0.4c

#########
%setup
#########
mkdir $SINGULARITY_ROOTFS/diffparcellate
cp -Rv . $SINGULARITY_ROOTFS/diffparcellate





%runscript
exec /diffparcellate/run.sh $@
