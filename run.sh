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


if [ "$#" -lt 3 ]
then
 echo ""
 echo "Usage: diffparcellate bids_dir output_dir {participant1,group1,participant2,group2,participant3,participant4,group3} <optional arguments>"
 echo ""
 echo " Required arguments:"
 echo "          [--in_prepdwi_dir PREPDWI_DIR]" 
 echo " Optional arguments:"
 echo "          [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL...]]"
 echo "          [--matching_T1w MATCHING_STRING"
 echo "          [--reg_init_participant PARTICIPANT_LABEL"
 echo "          [--parcellate_type PARCELLATE_TYPE (default: striatum_cortical; can alternatively specify config file) "
 echo ""
 echo "	Analysis levels:"
 echo "		participant1: T1 pre-processing and atlas registration"
 echo "		group1: generate QC for masking, linear and non-linear registration"
 echo "		participant2: volume-based tractography parcellation"
 echo "		group2: generate csv files for parcellation volume stats"
 echo "		participant3: surface-based displacement morphometry (LDDMM)"
 echo "		participant4: surface-based tractography parcellation"
 echo "		group3: generate surface-based analysis stats and results"
 echo ""
 echo "         Available parcellate types:"
 for parc in `ls $execpath/cfg/parcellate.*.cfg`
 do
     parc=${parc##*/parcellate.}
     parc=${parc%%.cfg}
     echo "         $parc"
 done



 exit 1
fi


in_bids=$1 
out_folder=$2 
analysis_level=$3


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
         parcellate_cfg=$parcellate_type
     else

 echo "ERROR: --parcellate_type $parcellate_type does not exist!"
 exit 1
fi


if [ ! -n "$in_prepdwi_dir" ]
then
    echo "ERROR: --in_prepdwi_dir must be specified!"
    exit 1
fi

if [ ! -e $in_prepdwi_dir ]
then
    echo "ERROR: in_prepdwi_dir $in_prepdwi_dir does not exist!"
	exit 1
fi


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

echo $participants
	

if [ "$analysis_level" = "participant1" ]
then
 echo " running participant1 level analysis"
 echo " import data and preproc T1, DWI"
  
 for subj in $subjlist 
 do

 #add on sub- if not exists
  subj=`fixsubj $subj`
 
 N_t1w=`eval ls $in_bids/$subj/anat/${subj}${searchstring_t1w} | wc -l`
 in_t1w=`eval ls $in_bids/$subj/anat/${subj}${searchstring_t1w} | head -n 1`

 echo Found $N_t1w matching T1w, using first found: $in_t1w

  pushd $work_folder
 echo importT1 $in_t1w $subj
  importT1 $in_t1w $subj
  popd

  if [ -n "$reg_init_subj" ]
  then
	echo $execpath/2.1_processT1_regFail $work_folder $reg_init_subj $subj
	$execpath/2.1_processT1_regFail $work_folder $reg_init_subj $subj
  else
 	echo $execpath/2.0_processT1 $work_folder $subj
	 $execpath/2.0_processT1 $work_folder $subj
  fi


 done

 elif [ "$analysis_level" = "group1" ]
 then

    echo "generate preproc QC reports"

    #need to make a subjlist for this command 
    mkdir -p $work_folder/etc
    qclist=$work_folder/etc/subjects
    rm -f $qclist
    touch $qclist
    for subj in $subjlist
    do
        subj=`fixsubj $subj`
        echo $subj >> $qclist
    done
    $execpath/3_genQC $work_folder $qclist



elif [ "$analysis_level" = "participant2" ]
then
 echo " running participant2 level analysis"
 echo "  probabilistic tracking and seed parcellation"

  bedpost_root=`realpath $in_prepdwi_dir/bedpost`
 # if [ ! -e $bedpost_root ]
  #then
 #  #try to locate prepdwi derivatives from bids input folder, use most recent
 #  bedpost_root=`ls -dt $in_bids/derivatives/prepdwi*/bedpost | head -n 1`
   

 # if [ ! -e  "$bedpost_root" ]
 # then
 #    echo "Cannot find bedpost folder in $in_bids/derivatives/prepdwi*, required for participant3 analysis"
 #    exit 1
 # fi



 for subj in $subjlist 
 do

 #add on sub- if not exists
  subj=`fixsubj $subj`

  if [ -n "$bedpost_root" ]
  then

   echo $execpath/4_genParcellationMNI $work_folder $bedpost_root $subj
   $execpath/4_genParcellationMNI $work_folder $bedpost_root $subj
   
   echo $execpath/5_cleanupBIDS $work_folder $out_folder $subj
   $execpath/5_cleanupBIDS $work_folder $out_folder $subj
  fi

 done

 elif [ "$analysis_level" = "group2" ]
 then

    echo "analysis level group2, computing parcellation volumes"

    #need to make a subjlist for this command 
    list=$work_folder/subjects_group2
    rm -f $list
    touch $list
    for subj in $subjlist
    do
        subj=`fixsubj $subj`
        echo $subj >> $list
    done
    echo $execpath/8.1_computeThreshDiffParcVolumeLeftRight $work_folder $list
    $execpath/8.1_computeThreshDiffParcVolumeLeftRight $work_folder $list
    echo $execpath/8.3_computeMaxProbDiffParcVolumeLeftRight $work_folder $list
    $execpath/8.3_computeMaxProbDiffParcVolumeLeftRight $work_folder $list

 
 elif [ "$analysis_level" = "participant3" ]
 then

    echo "analysis level participant3, computing surfdisp target processing"
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

     for subj in $subjlist 
     do

      #add on sub- if not exists
      subj=`fixsubj $subj`

      source $parcellate_cfg

      echo propLabels_reg_bspline_f3d t1 $labelgroup_prob $atlas  $subj -L
      propLabels_reg_bspline_f3d t1 $labelgroup_prob $atlas  $subj -L
      echo propLabels_backwards_intersubj_aladin t1  ${labelgroup_prob}_bspline_f3d_$atlas  $atlas $subj -L
      propLabels_backwards_intersubj_aladin t1  ${labelgroup_prob}_bspline_f3d_$atlas  $atlas $subj -L
      echo computeSurfaceDisplacementsSingleStructure $subj $parcellate_cfg  -N
      computeSurfaceDisplacementsSingleStructure $subj $parcellate_cfg  -N

     done
     
     popd


 elif [ "$analysis_level" = "participant4" ]
 then

    echo "analysis level participant4, computing surface-based tractography"

    bedpost_root=`realpath $in_prepdwi_dir/bedpost`
     for subj in $subjlist 
     do

      #add on sub- if not exists
      subj=`fixsubj $subj`

      echo $execpath/9.2_runSurfBasedTractography $work_folder $bedpost_root $parcellate_cfg $subj
      $execpath/9.2_runSurfBasedTractography $work_folder $bedpost_root $parcellate_cfg $subj

     done
     


 elif [ "$analysis_level" = "group3" ]
 then

    echo "analysis level group3, computing surf-based analysis"

    mkdir -p $work_folder/etc
    list=$work_folder/etc/subjects.$analysis_level
    rm -f $list
    touch ${list}
    for subj in $subjlist
    do
        subj=`fixsubj $subj`
        echo $subj >> $list
    done

    source $parcellate_cfg
    pushd $work_folder      
    runMatlabCmd  analyzeSurfData "'$list'" "'$in_prepdwi_dir'" "'$parcellation_name'"
    popd


 else
  echo "analysis_level $analysis_level does not exist"
  exit 1
fi


