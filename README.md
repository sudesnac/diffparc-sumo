# diffparc-sumo
Diffusion parcellation &amp; SUrface-based MOrphometry

```
Usage: diffparcellate bids_dir output_dir {participant,group,participant2,group2} <optional arguments>

 Required arguments:
          [--in_prepdwi_dir PREPDWI_DIR]
 Optional arguments:
          [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL...]]
          [--matching_T1w MATCHING_STRING
          [--reg_init_participant PARTICIPANT_LABEL
          [--parcellate_type PARCELLATE_TYPE (default: striatum_cortical; can alternatively specify config file)
          [--seed_res RES_MM ] (default: 1)
          [--nsamples N ] (default: 1000)

 Optional arguments for participant level:
          [--skip_postproc] (skips post-processing after tractography - use when large # of targets, e.g. HCP-MMP)

	Analysis levels:
		participant: T1 pre-proc, label prop, vol-based tractography
		group: generate csv files for parcellation volume & dti stats
		participant2: T1 pre-proc, label prop, surface-based displacement morphometry (LDDMM) & surf-based tractography
		group2: generate surface-based analysis stats csv

  note:  participant2/group2 can now be run without participant/group analysis..

         Available parcellate types:
         CIT168_striatum_cortical
         CIT168_vtasnc_avgstriatum_avoidcortical_coreOnly
         CIT168_vtasnc_striatum_avoidcortical_coreOnly
         CIT168_vtasncsnr_striatum_avoidcortical_coreOnly
         fullBF_hcpmmpVolMNI
         striatum_cortical
         striatum_hcpmmpVolMNI
         vta_snc_cortical
         vta_snc_cortical_avoidstriatum
         vta_snc_striatum
         vta_snc_striatum_avoidcortical
         vta_snc_v2_cortical
         vta_snc_v2_cortical_avoidstriatum
         vta_snc_v2_striatum
         vta_snc_v2_striatum_avoidcortical
         vta_snc_v2_striatum_avoidcortical_coreOnly
```
