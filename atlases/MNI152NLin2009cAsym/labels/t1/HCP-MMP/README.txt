From:  https://figshare.com/articles/HCP-MMP1_0_projected_on_MNI2009a_GM_volumetric_in_NIfTI_format/3501911


Only modification was to resample to change # of voxels in each dimension to match MNI version of 193x229x193 (instead of 256x256x256) - should only pad out and not change segmentations in any way..
reg_resample  -ref t1.nii.gz -flo MMP_in_MNI_corr.nii.gz -NN 0 -res MMP_in_MNI_corr.resampled.nii.gz


Note that, this is not the best way to get Glasser parcellations - better to go from surface of each subject:
https://figshare.com/articles/HCP-MMP1_0_volumetric_NIfTI_masks_in_native_structural_space/4249400

