function genConnMapFeatures (connmap_nii_path,seed_nii_path,out_mat)

%connmap_nii_path='connMap.4d.nii.gz';
%seed_nii_path='seed_dtires.nii.gz';
%out_mat='connMap_features.mat';


connmap_nii =load_nifti(connmap_nii_path);
seed_nii=load_nifti(seed_nii_path);
%want to save .mat file with:
% NxM feature matrix (N=# of voxels in seed, M=# of targets, 360 for HCP) 
% mask (Nx,Ny,Nz)

mask=seed_nii.vol>0;
seed_mask=seed_nii.vol(mask);

N=size(seed_mask,1);
M=size(connmap_nii.vol,4);

mask_rep=repmat(mask,[1,1,1,M]);

connmap_feats=reshape(connmap_nii.vol(mask_rep),[N,M]);


save(out_mat,'connmap_feats','mask','connmap_nii_path','seed_nii_path');


% Example of k-means to demonstrate how to process features into a volume

%k=20;
%clustered=kmeans(connmap_feats,k);

%create new volume same size as binary mask
%cluster_vol=zeros(size(mask));

%set masked voxels with results of clustering
%cluster_vol(mask)=clustered;

%niftiwrite(cluster_vol,sprintf('test_kmeans_k-%d',k));