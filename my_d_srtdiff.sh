#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

mod_name=$(basename $0)
source $MY_SRTDIFF_CFG_FILEPATH

#----[sources]---------------------------------------------------------------

source $dock_proj_folder/common_bash_functions.sh

#----[temp files and termination]--------------------------------------------

terminated=0

function fnxOnEnd
{
    ((terminated==0)) && { rm -f $tmp1 $tmp2; }
    terminated=1
}

tmp1=`mktemp`
tmp2=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[helper functions]------------------------------------------------------

function normalize
{
    local _fileno="$1"
    local _in="$2"

    local _meta="$(file $_in)"
    local _out=$dock_data_folder/${_fileno}.norm.srt

    ((debug)) && { echo "d> filemeta filepath=$_in meta=$_meta"; }
    if ! srtdf_utf8_base.sh $_in > $_out
    then
        return 1
    fi

    return 0
}

function infer_end_time
{
    local _fileno="$1"

    local _in=$dock_data_folder/${_fileno}.norm.srt
    local _out=$dock_data_folder/${_fileno}.iet.srt

    local _dbg_opt=""
    local _dbg_out="/dev/null"
    if ((debug))
    then
        _dbg_opt=" -d "
        _dbg_out="$dock_data_folder/${_fileno}.iet.dbg.csv"
    fi

    cat $_in |\
    srtdf_infer_endtime.sh \
        -t $infer_end_time_tolerance \
        -w $infer_end_time_wpm       \
        $_dbg_opt                    \
        1>$_out 2>$_dbg_out
}

function perform_srt_diff
{
    local _output="$1" 

    srt_diff.sh \
        -d $dock_data_folder            \
        -O $dock_data_folder/1.iet.srt  \
        -T $dock_data_folder/2.iet.srt  \
        > $_output
}

function dump_lev_histogram
{
    local _output="$1" 

    srtdf_lev_hist.sh $dock_data_folder/srtlev.csv > $_output
}

#----[main]------------------------------------------------------------------

srt_1_filepath="$1"
srt_2_filepath="$2"

if ((debug))
then
    ((debug)) && { echo "#--{configuration}--"; }
    cat <<EOD >&2
d> cfg dock_data_folder=$dock_data_folder
d> cfg dock_proj_folder=$dock_proj_folder
d> cfg infer_end_time_tolerance=$infer_end_time_tolerance
d> cfg infer_end_time_wpm=$infer_end_time_wpm
d> in  srt_1_filepath=$srt_1_filepath
d> in  srt_2_filepath=$srt_2_filepath
EOD
fi

PATH=$PATH:$dock_proj_folder

#+---------------------+
#| normalize srt files |
#+---------------------+

((debug)) && { echo "#--{normalizing srt files}--"; }

if ! normalize 1 $srt_1_filepath
then
    exit 2
fi

if ! normalize 2 $srt_2_filepath
then
    exit 2
fi

#+--------------------+
#| inferring end time |
#+--------------------+

((debug)) && { echo "#--{inferring end times}--"; }

if ! infer_end_time 1
then
    exit 2
fi

if ! infer_end_time 2
then
    exit 2
fi

#+------------------+
#| perform srt diff |
#+------------------+

((debug)) && { echo "#--{performing srt diff}--"; }

if ! perform_srt_diff $tmp1
then
    exit 2
fi

read lev_dist srtlev_filepath srtcomp_filepath srtcomplev_filepath <<< $(cat $tmp1)
echo "$lev_dist" > $dock_data_folder/levdist.txt

#+---------------------------------------+
#| dump histogram of levenshtein details |
#+---------------------------------------+

((debug)) && { echo "#--{dumping levenshtein histogram}--"; }

if ! dump_lev_histogram $dock_data_folder/levhist.csv
then
    exit 2
fi

chmod +r $dock_data_folder/levhist.csv

exit 0

