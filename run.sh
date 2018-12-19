#!/bin/bash

function die {
 echo $1 >&2
 exit 1
}

function fixsubj {
#add on sub- if not exists
subj=$1
 if [ ! "${subj:0:4}" = "sub-" ]
 then
  subj="sub-$subj"
 fi
 echo $subj
}

function fixsess {
#add on ses- if not exists
sess=$1
 if [ ! "${sess:0:4}" = "ses-" ]
 then
  sess="sub-$sess"
 fi
 echo $sess
}


execpath=`dirname $0`
execpath=`realpath $execpath`

cfg_dir=$execpath/cfg

in_atlas_dir=$execpath/atlases

matching_dwi=
participant_label=
matching_T1w=
n_cpus=8
reg_init_subj=
parcellate_type=striatum_cortical
in_prepdwi_dir=

legacy_dwi_proc=0
legacy_dwi_type=dwi_eddy
legacy_dwi_path=dwi/uncorrected_denoise_unring_eddy

seed_res=1
nsamples=1000

if [ "$#" -lt 3 ]
then
 echo "Usage: diffparcellate bids_dir output_dir {participant,group,participant2,group2,participant3,participant4,group3} <optional arguments>"
 echo ""
 echo " Required arguments:"
 echo "          [--in_prepdwi_dir PREPDWI_DIR]" 
 echo " Optional arguments:"
 echo "          [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL...]]"
 echo "          [--matching_T1w MATCHING_STRING"
 echo "          [--reg_init_participant PARTICIPANT_LABEL"
 echo "          [--parcellate_type PARCELLATE_TYPE (default: striatum_cortical; can alternatively specify config file) "
 echo "          [--seed_res RES_MM ] (default: 1)"
 echo "          [--nsamples N ] (default: 1000)"
 echo ""
 echo "	Analysis levels:"
 echo "		participant: T1 pre-processing, atlas label prop, vol-based tractography"
 echo "		group: generate csv files for parcellation volume & dti stats"
 echo "		participant2: surface-based displacement morphometry (LDDMM) & surf-based tractography"
 echo "		group2: generate surface-based analysis stats csv"
 echo ""
 echo "         Available parcellate types:"
 for parc in `ls $execpath/cfg/parcellate.*.cfg`
 do
     parc=${parc##*/parcellate.}
     parc=${parc%%.cfg}
     echo "         $parc"
 done



 exit 0
fi


in_bids=$1 
out_folder=$2 
analysis_level=$3

mkdir -p $out_folder 
out_folder=`realpath $out_folder`

shift 3



while :; do
      case $1 in
     -h|-\?|--help)
	     usage
            exit
              ;;
     --n_cpus )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                n_cpus=$2
                  shift
	      else
              die 'error: "--n_cpus" requires a non-empty option argument.'
            fi
              ;;

     --participant_label )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                participant_label=$2
                  shift
	      else
              die 'error: "--participant" requires a non-empty option argument.'
            fi
              ;;
     --participant_label=?*)
          participant_label=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --participant_label=)         # handle the case of an empty --participant=
         die 'error: "--participant_label" requires a non-empty option argument.'
          ;;


           --enable_legacy_dwi )       # takes an option argument; ensure it has been specified.
            legacy_dwi_proc=1;;
#-------------------

           --parcellate_type )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                parcellate_type=$2
                  shift
	      else
              die 'error: "--parcellate_type" requires a non-empty option argument.'
            fi
              ;;
     --parcellate_type=?*)
          parcellate_type=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --parcellate_type=)         # handle the case of an empty --participant=
         die 'error: "--parcellate_type" requires a non-empty option argument.'
          ;;


#-------------------

           --seed_res )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                seed_res=$2
                  shift
	      else
              die 'error: "--seed_res" requires a non-empty option argument.'
            fi
              ;;
     --seed_res=?*)
          seed_res=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --seed_res=)         # handle the case of an empty --participant=
         die 'error: "--seed_res" requires a non-empty option argument.'
          ;;

#-------------------

           --nsamples )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                nsamples=$2
                  shift
	      else
              die 'error: "--nsamples" requires a non-empty option argument.'
            fi
              ;;
     --nsamples=?*)
          nsamples=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --nsamples=)         # handle the case of an empty --participant=
         die 'error: "--nsamples" requires a non-empty option argument.'
          ;;


#-------------------

           --in_prepdwi_dir )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                in_prepdwi_dir=$2
                  shift
	      else
              die 'error: "--in_prepdwi_dir" requires a non-empty option argument.'
            fi
              ;;
     --in_prepdwi_dir=?*)
          in_prepdwi_dir=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --in_prepdwi_dir=)         # handle the case of an empty --participant=
         die 'error: "--in_prepdwi_dir" requires a non-empty option argument.'
          ;;
#-------------------

           --reg_init_participant )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                reg_init_subj=$2
                  shift
	      else
              die 'error: "--reg_init_participant" requires a non-empty option argument.'
            fi
              ;;
     --reg_init_participant=?*)
          reg_init_subj=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --reg_init_participant=)         # handle the case of an empty --participant=
         die 'error: "--reg_init_participant" requires a non-empty option argument.'
          ;;

      
#-------------------
      
      
      --matching_dwi )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                matching_dwi=$2
                  shift
	      else
              die 'error: "--matching_dwi" requires a non-empty option argument.'
            fi
              ;;
     --matching_dwi=?*)
          matching_dwi=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --matching_dwi=)         # handle the case of an empty --acq=
         die 'error: "--matching_dwi" requires a non-empty option argument.'
          ;;
     --matching_T1w )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                matching_T1w=$2
                  shift
	      else
              die 'error: "--matching_T1w" requires a non-empty option argument.'
            fi
              ;;
     --matching_T1w=?*)
          matching_T1w=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --matching_T1w=)         # handle the case of an empty --acq=
         die 'error: "--matching_dwi" requires a non-empty option argument.'
          ;;


      -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
              ;;
     *)               # Default case: No more options, so break out of the loop.
          break
    esac
  
 shift
  done


shift $((OPTIND-1))


participants=$in_bids/participants.tsv
work_folder=$out_folder/work
derivatives=$out_folder #bids derivatives

if [ -e $execpath/cfg/parcellate.$parcellate_type.cfg ]
then
     parcellate_cfg=$execpath/cfg/parcellate.$parcellate_type.cfg 
 elif [ -e $parcellate_type ]
  then 
         parcellate_cfg=`realpath $parcellate_type`
     else

 echo "ERROR: --parcellate_type $parcellate_type does not exist!"
 exit 1
fi



if [ ! -n "$in_prepdwi_dir" ] # if not specified
then

    #if not specified, use stored value:
    if [ -e $work_folder/etc/in_prepdwi_dir ]
    then
        in_prepdwi_dir=`cat $work_folder/etc/in_prepdwi_dir`
        echo "Using previously defined --in_prepdwi_dir $in_prepdwi_dir"
    else
        echo "ERROR: --in_prepdwi_dir must be specified!"
        exit 1
    fi

fi

if [ ! -e $in_prepdwi_dir ]
then
    echo "ERROR: in_prepdwi_dir $in_prepdwi_dir does not exist!"
	exit 1
fi

in_prepdwi_dir=`realpath $in_prepdwi_dir`


if [ -e $in_bids ]
then
	in_bids=`realpath $in_bids`
else
	echo "ERROR: bids_dir $in_bids does not exist!"
	exit 1
fi

if [ -n "$matching_dwi" ]
then
  searchstring_dwi=\*${matching_dwi}\*dwi.nii*
else
  searchstring_dwi=*dwi.nii*
fi

if [ -n "$matching_T1w" ]
then
  searchstring_t1w=\*${matching_T1w}\*T1w.nii*
else
  searchstring_t1w=*T1w.nii*
fi

if [ -n "$participant_label" ]
then
subjlist=`echo $participant_label | sed  's/,/\ /g'` 
else
subjlist=`tail -n +2 $participants | awk '{print $1}'`
fi





mkdir -p $work_folder $derivatives
work_folder=`realpath $work_folder`

#in_prepdwi_dir defined:
#save it to file
mkdir -p $work_folder/etc
echo "$in_prepdwi_dir" > $work_folder/etc/in_prepdwi_dir


#surf disp requires this (can edit later to build into that and remove this..)
index_list=$work_folder/etc/surfdisp_seed.csv
if [ ! -e $index_list ]
then
  if $(mkdir -p $work_folder/etc/lock_index)
  then
	echo "seed,0" > $index_list
	rmdir $work_folder/etc/lock_index
  fi
 fi
index_list=`realpath $index_list`

#exports for called scripts
export legacy_dwi_proc in_atlas_dir parcellate_cfg index_list cfg_dir


#use symlinks instead of copying 
for atlas_dir in `ls -d $in_atlas_dir/*`
do
 atlas_name=${atlas_dir##*/}


 if ! test -h $work_folder/$atlas_name 
 then
	if test -d $work_folder/$atlas_name 
	then

	   echo "atlas exists and is not a symlink, so can remove it"
   	   rm -rf $work_folder/$atlas_name
    	fi
	
	echo ln -sfv $atlas_dir $work_folder/$atlas_name
	 ln -sfv $atlas_dir $work_folder/$atlas_name

 fi
 
done

echo $participants
	

if [ "$analysis_level" = "participant" ]
then
 echo " running participant level analysis"
 echo " import data from prepdwi"
  
 for subj in $subjlist 
 do

 #add on sub- if not exists
  subj=`fixsubj $subj`

   #loop over sub- and sub-/ses-
    for subjfolder in `ls -d $in_bids/$subj/dwi $in_bids/$subj/ses-*/dwi 2> /dev/null`
    do

        subj_sess_dir=${subjfolder%/dwi}
        subj_sess_dir=${subj_sess_dir##$in_bids/}
        if echo $subj_sess_dir | grep -q '/'
        then
            sess=${subj_sess_dir##*/}
            subj_sess_prefix=${subj}_${sess}
        else
            subj_sess_prefix=${subj}
        fi
        echo subjfolder $subjfolder
        echo subj_sess_dir $subj_sess_dir
        echo sess $sess
        echo subj_sess_prefix $subj_sess_prefix

	if [ -e $in_prepdwi_dir/work/$subj_sess_prefix/t1/t1.brain.inorm.nii.gz ]
	then
		echo "using pre-processed t1 from prepdwi"
		mkdir -p $work_folder/$subj_sess_prefix/t1
		mkdir -p $work_folder/$subj_sess_prefix/reg/

		for infile in `ls $in_prepdwi_dir/work/$subj_sess_prefix/t1/* $in_prepdwi_dir/work/$subj_sess_prefix/reg/*/*/*`
		do	
			filepath=${infile%/*}	
			filepath=${filepath##${in_prepdwi_dir}/work/}
			mkdir -p $work_folder/$filepath
			cp -v $infile $work_folder/$filepath
		done

 
     echo $execpath/2.0_processT1 $work_folder $subj_sess_prefix
    $execpath/2.0_processT1 $work_folder $subj_sess_prefix
   
    else

        echo "Cannot find $in_prepdwi_dir/work/$subj_sess_prefix/t1/t1.brain.inorm.nii.gz, skipping ...."
        continue


 
  fi #after import from bids or prepdwi
  
 done #ses
 done


echo " running probabilistic tracking and seed parcellation (formerly participant2 level)"

 bedpost_root=`realpath $in_prepdwi_dir/bedpost`

 for subj in $subjlist 
 do

 #add on sub- if not exists
  subj=`fixsubj $subj`

   #loop over sub- and sub-/ses-
    for subjfolder in `ls -d $in_bids/$subj/dwi $in_bids/$subj/ses-*/dwi 2> /dev/null`
    do

        subj_sess_dir=${subjfolder%/dwi}
        subj_sess_dir=${subj_sess_dir##$in_bids/}
        if echo $subj_sess_dir | grep -q '/'
        then
            sess=${subj_sess_dir##*/}
            subj_sess_prefix=${subj}_${sess}
        else
            subj_sess_prefix=${subj}
        fi
        echo subjfolder $subjfolder
        echo subj_sess_dir $subj_sess_dir
        echo sess $sess
        echo subj_sess_prefix $subj_sess_prefix



  if [ -n "$bedpost_root" ]
  then

   echo $execpath/4_genParcellationMNI $work_folder $bedpost_root $seed_res $nsamples $subj_sess_prefix
   $execpath/4_genParcellationMNI $work_folder $bedpost_root $seed_res $nsamples $subj_sess_prefix
  
   nsamples_tracts=`bashcalc "scale=0; $nsamples/100"`
   if [ "$nsamples_tracts" -lt 10 ]
   then
	   nsamples_tracts=10
   fi
   echo "using N=$nsamples_tracts probabilistic tracts for simple tract pathway maps"
   echo $execpath/4.1_genTractMaps $work_folder $bedpost_root $nsamples_tracts $subj_sess_prefix
   $execpath/4.1_genTractMaps $work_folder $bedpost_root $nsamples_tracts $subj_sess_prefix
 
   echo $execpath/4.2_genParcellationNlinMNI $work_folder $subj_sess_prefix
   $execpath/4.2_genParcellationNlinMNI $work_folder $subj_sess_prefix

   echo $execpath/5_cleanupBIDS $work_folder $out_folder $subj_sess_prefix
   $execpath/5_cleanupBIDS $work_folder $out_folder $subj_sess_prefix
  fi

 done #ses
 done

 elif [ "$analysis_level" = "group" ]
 then

    echo "analysis level group, computing parcellation volumes"

    #need to make a subjlist for this command 
    list=$work_folder/subjects_group.$RANDOM
    rm -f $list
    touch $list
    for subj in $subjlist
    do
        subj=`fixsubj $subj`


    #loop over sub- and sub-/ses-
    for subjfolder in `ls -d $in_bids/$subj/dwi $in_bids/$subj/ses-*/dwi 2> /dev/null`
    do

        subj_sess_dir=${subjfolder%/dwi}
        subj_sess_dir=${subj_sess_dir##$in_bids/}
        if echo $subj_sess_dir | grep -q '/'
        then
            sess=${subj_sess_dir##*/}
            subj_sess_prefix=${subj}_${sess}
        else
            subj_sess_prefix=${subj}
        fi
        echo subjfolder $subjfolder
        echo subj_sess_dir $subj_sess_dir
        echo sess $sess
        echo subj_sess_prefix $subj_sess_prefix



        echo $subj_sess_prefix >> $list
    done #ses
    done
    csv_folder=$out_folder/csv
    mkdir -p $csv_folder
    echo $execpath/8.3_computeMaxProbDiffParcVolumeLeftRight $work_folder $csv_folder $list
    $execpath/8.3_computeMaxProbDiffParcVolumeLeftRight $work_folder $csv_folder $list
    echo $execpath/8.4_computeMaxProbDiffParcFALeftRight $work_folder $csv_folder $list
    $execpath/8.4_computeMaxProbDiffParcFALeftRight $work_folder $csv_folder $list
    echo $execpath/8.5_computePathsParcFALeftRight $work_folder $csv_folder $list
    $execpath/8.5_computePathsParcFALeftRight $work_folder $csv_folder $list

    

    #delete after done
    rm -f $list

 elif [ "$analysis_level" = "participant2" ]
 then

    echo "analysis level participant2, surface-based processing"
    echo "   computing surface-based morphometry (formerly analysis level participant3)"
     pushd $work_folder

     #first prep template (if not done yet, run it once, uses mkdir lock for synchronization, and wait time of 5 minutes)
     template_lock=etc/run_template.lock
     if $(mkdir -p $template_lock)
     then
         echo computeSurfaceDisplacementsSingleStructure template_placeholder  $parcellate_cfg -N -t
         computeSurfaceDisplacementsSingleStructure template_placeholder  $parcellate_cfg -N -t
        rm $template_lock
	 else
	    sleep 300 #shouldn't take longer than 5 min
     fi

    popd

     for subj in $subjlist 
     do

      #add on sub- if not exists
      subj=`fixsubj $subj`

      
      #loop over sub- and sub-/ses-
    for subjfolder in `ls -d $in_bids/$subj/dwi $in_bids/$subj/ses-*/dwi 2> /dev/null`
    do

        subj_sess_dir=${subjfolder%/dwi}
        subj_sess_dir=${subj_sess_dir##$in_bids/}
        if echo $subj_sess_dir | grep -q '/'
        then
            sess=${subj_sess_dir##*/}
            subj_sess_prefix=${subj}_${sess}
        else
            subj_sess_prefix=${subj}
        fi
        echo subjfolder $subjfolder
        echo subj_sess_dir $subj_sess_dir
        echo sess $sess
        echo subj_sess_prefix $subj_sess_prefix


      source $parcellate_cfg
      if [ ! -e $work_folder/surfdisp_singlestruct_${parcellation_name}/${subj_sess_prefix}/templateSurface_seed_inout.vtk ]
	then
        pushd $work_folder
	      echo propLabels_reg_bspline_f3d t1 $labelgroup_prob $atlas  $subj_sess_prefix -L
	      propLabels_reg_bspline_f3d t1 $labelgroup_prob $atlas  $subj_sess_prefix -L
	      echo propLabels_backwards_intersubj_aladin t1  ${labelgroup_prob}_bspline_f3d_$atlas  $atlas $subj_sess_prefix -L
	      propLabels_backwards_intersubj_aladin t1  ${labelgroup_prob}_bspline_f3d_$atlas  $atlas $subj_sess_prefix -L
	      echo computeSurfaceDisplacementsSingleStructure $subj_sess_prefix $parcellate_cfg  -N
	      computeSurfaceDisplacementsSingleStructure $subj_sess_prefix $parcellate_cfg  -N
          popd
	fi

     #make BIDS links for output
     out_subj_dir=$out_folder/$subj_sess_dir/anat

     #surf parc in T1w space (vtk file, open in slicer or paraview)
     vec_mni=$work_folder/surfdisp_singlestruct_$parcellation_name/${subj_sess_prefix}/templateSurface_seed_disp.vtk
     inout_mni=$work_folder/surfdisp_singlestruct_$parcellation_name/${subj_sess_prefix}/templateSurface_seed_inout.vtk
     
     out_vec_mni=$out_subj_dir/${subj_sess_prefix}_space-${atlas}_${bids_tags}_surfmorphvec.vtk
     out_inout_mni=$out_subj_dir/${subj_sess_prefix}_space-${atlas}_${bids_tags}_surfmorphinout.vtk

     #surf vtk of avg template with displacements
     mkdir -p $out_subj_dir
     ln -srfv $vec_mni $out_vec_mni
     ln -srfv $inout_mni $out_inout_mni


     done #ses
 done
     

    echo "computing surface-based tractography, formerly analysis level participant4"

    bedpost_root=`realpath $in_prepdwi_dir/bedpost`
     for subj in $subjlist 
     do

      #add on sub- if not exists
      subj=`fixsubj $subj`


      #loop over sub- and sub-/ses-
    for subjfolder in `ls -d $in_bids/$subj/dwi $in_bids/$subj/ses-*/dwi 2> /dev/null`
    do

        subj_sess_dir=${subjfolder%/dwi}
        subj_sess_dir=${subj_sess_dir##$in_bids/}
        if echo $subj_sess_dir | grep -q '/'
        then
            sess=${subj_sess_dir##*/}
            subj_sess_prefix=${subj}_${sess}
        else
            subj_sess_prefix=${subj}
        fi
        echo subjfolder $subjfolder
        echo subj_sess_dir $subj_sess_dir
        echo sess $sess
        echo subj_sess_prefix $subj_sess_prefix


    source $parcellate_cfg
	if [ ! -e $work_folder/$subj_sess_prefix/bedpost.${parcellation_name}/vertexTract/fdt_matrix2.dot ]
	then
	      echo $execpath/9.2_runSurfBasedTractography $work_folder $bedpost_root $parcellate_cfg $nsamples $subj_sess_prefix
	      $execpath/9.2_runSurfBasedTractography $work_folder $bedpost_root $parcellate_cfg $nsamples $subj_sess_prefix
	fi

       pushd $work_folder      
       runMatlabCmd  processSubjSurfData "'$subj_sess_prefix'" "'$in_prepdwi_dir'" "'$parcellation_name'" "'$target_labels_txt'"
       popd


     #make BIDS links for output
     out_subj_dir=$out_folder/$subj_sess_dir/anat

     #surf parc in T1w space (vtk file, open in slicer or paraview)
     parc_surf=$work_folder/subj_vtk/${subj_sess_prefix}.parc.vtk
     
     out_parc_surf=$out_subj_dir/${subj_sess_prefix}_space-T1w_${bids_tags}_surfdiffparc.vtk

     #surf vtk of parcellation
     mkdir -p $out_subj_dir
     ln -srfv $parc_surf $out_parc_surf



    done #ses
     done
     


 elif [ "$analysis_level" = "group2" ]
 then

     echo "analysis level group2, computing surf-based analysis (formerly group3)" 

    mkdir -p $work_folder/etc
    list=$work_folder/etc/subjects.$analysis_level.$RANDOM
    rm -f $list
    touch ${list}
    for subj in $subjlist
    do
        subj=`fixsubj $subj`

#loop over sub- and sub-/ses-
    for subjfolder in `ls -d $in_bids/$subj/dwi $in_bids/$subj/ses-*/dwi 2> /dev/null`
    do

        subj_sess_dir=${subjfolder%/dwi}
        subj_sess_dir=${subj_sess_dir##$in_bids/}
        if echo $subj_sess_dir | grep -q '/'
        then
            sess=${subj_sess_dir##*/}
            subj_sess_prefix=${subj}_${sess}
        else
            subj_sess_prefix=${subj}
        fi
        echo subjfolder $subjfolder
        echo subj_sess_dir $subj_sess_dir
        echo sess $sess
        echo subj_sess_prefix $subj_sess_prefix

        echo $subj_sess_prefix >> $list
    done #ses
    done

    source $parcellate_cfg
    pushd $work_folder      
    runMatlabCmd  analyzeSurfData "'$list'" "'$in_prepdwi_dir'" "'$parcellation_name'" "'$target_labels_txt'" "'$out_folder/csv'" "'${bids_tags}'"
    popd

    rm -f $list

 else
  echo "analysis_level $analysis_level does not exist"
  exit 1
fi


