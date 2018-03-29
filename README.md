# diffparc-sumo
Diffusion parcellation &amp; SUrface-based MOrphometry

```

Usage: diffparcellate bids_dir output_dir {participant1,group1,participant2,group2,participant3,participant4,group3} <optional arguments>

 Required arguments:
          [--in_prepdwi_dir PREPDWI_DIR]
 Optional arguments:
          [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL...]]
          [--matching_T1w MATCHING_STRING
          [--reg_init_participant PARTICIPANT_LABEL
          [--parcellate_type PARCELLATE_TYPE (default: striatum_cortical; can alternatively specify config file)

	Analysis levels:
		participant1: T1 pre-processing and atlas registration
		group1: generate QC for masking, linear and non-linear registration
		participant2: volume-based tractography parcellation
		group2: generate csv files for parcellation volume stats
		participant3: surface-based displacement morphometry (LDDMM)
		participant4: surface-based tractography parcellation
		group3: generate surface-based analysis stats and results

         Available parcellate types:
         striatum_cortical
         vta_snc_cortical
         vta_snc_cortical_avoidstriatum
         vta_snc_striatum
         vta_snc_striatum_avoidcortical
```
