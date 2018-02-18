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


matching_dwi=
participant_label=
matching_T1w=
n_cpus=8
reg_init_subj=
global_config_file=


if [ "$#" -lt 3 ]
then
 echo "Usage: diffparcellate bids_dir output_dir {participant1,group1,participant2,participant3,group2} <optional arguments>"
 echo "          [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL...]]"
 echo "          [--matching_dwi MATCHING_PATTERN"
 echo "          [--matching_T1w MATCHING_STRING"
 echo "          [--reg-init-participant PARTICIPANT_LABEL"
 echo "          [--global-config-file CONFIG_FILE  (required)"
 echo "          [--n_cpus] NCPUS (for bedpost, default: 8) "
 echo ""

#add options for:
#  bedpost folder
#  parcellation type (vtasn, striatum)

#remove options for:
#  global config file



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



           --global-config-file )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                global_config_file=$2
                  shift
	      else
              die 'error: "--global-config-file" requires a non-empty option argument.'
            fi
              ;;
     --global-config-file=?*)
          global_config_file=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --global-config-file=)         # handle the case of an empty --participant=
         die 'error: "--global-config-file" requires a non-empty option argument.'
          ;;




           --reg-init-participant )       # takes an option argument; ensure it has been specified.
          if [ "$2" ]; then
                reg_init_subj=$2
                  shift
	      else
              die 'error: "--reg-init-participant" requires a non-empty option argument.'
            fi
              ;;
     --reg-init-participant=?*)
          reg_init_subj=${1#*=} # delete everything up to "=" and assign the remainder.
            ;;
          --reg-init-participant=)         # handle the case of an empty --participant=
         die 'error: "--reg-init-participant" requires a non-empty option argument.'
          ;;

      
      
      
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


echo matching_dwi=$matching_dwi
echo participant_label=$participant_label

participants=$in_bids/participants.tsv
work_folder=$out_folder/work
derivatives=$out_folder #bids derivatives

if [ ! -n "$global_config_file" ]
then
    echo "ERROR: --global-config-file MUST be set!"
    exit 1
else
    if [ -e $global_config_file ]
    then
        source $global_config_file
    else
    echo "ERROR: --global-config-file $global_config_file does not exist!"
    exit 1
    fi
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
 echo $execpath/2.0_processT1 $work_folder $subj
 $execpath/2.0_processT1 $work_folder $subj
 done

 elif [ "$analysis_level" = "group1" ]
 then

    echo "generate preproc QC reports"

    #need to make a subjlist for this command 
    qclist=$work_folder/subjects
    rm -f $qclist
    touch $qclist
    for subj in $subjlist
    do
        subj=`fixsubj $subj`
        echo $subj >> $qclist
    done
    3_genQC $work_folder $qclist


elif [ "$analysis_level" = "participant2" ]
then
 echo " running participant2 level analysis"
 echo "  reprocessing for failed intersubj reg" 

 for subj in $subjlist 
 do

 #add on sub- if not exists
  subj=`fixsubj $subj`

  if [ -n "$reg_init_subj" ]
  then
  echo $execpath/2.1_processT1_regFail $work_folder $reg_init_subj $subj
  $execpath/2.1_processT1_regFail $work_folder $reg_init_subj $subj
  else
    echo "participant3 requires --reg-init-participant PARTICIPANT_LABEL to be defined"
    exit 1
  fi
  
 done


elif [ "$analysis_level" = "participant3" ]
then
 echo " running participant3 level analysis"
 echo "  probabilistic tracking and seed parcellation"

  #try to locate prepdwi derivatives from bids input folder, use most recent
  bedpost_root=`ls -dt $in_bids/derivatives/prepdwi*/bedpost | head -n 1`

  if [ ! -e  "$bedpost_root" ]
  then
     echo "Cannot find bedpost folder in $in_bids/derivatives/prepdwi*, required for participant3 analysis"
     exit 1
  fi



 for subj in $subjlist 
 do

 #add on sub- if not exists
  subj=`fixsubj $subj`

  if [ -n "$bedpost_root" ]
  then

   $execpath/4_genParcellationMNI $work_folder $bedpost_root $subj
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



 else
  echo "analysis_level $analysis_level does not exist"
  exit 1
fi


