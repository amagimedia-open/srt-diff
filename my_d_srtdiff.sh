#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

mod_name=$(basename $0)

#see -e in docker run (in my_h_srtdiff.sh)
debug=$SRTDIFF_DEBUG
dock_proj_folder=$SRTDIFF_PROJ_FOLDER
dock_data_folder=$SRTDIFF_DATA_FOLDER

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
    if [[ $_meta =~ ASCII ]]
    then
        cp $_in $_out
    elif [[ $_meta =~ UTF-8 ]]
    then
        if ! srtdf_utf8_base.sh $_in > $_out
        then
            return 1
        fi
    else
        error_message "unexpected-format $_meta"
        return 1
    fi

    ((debug)) && { echo "d> created file=$_out"; }

    return 0
}

#----[main]------------------------------------------------------------------

srt_1_filepath="$1"
srt_2_filepath="$2"

if ((debug))
then
    cat <<EOD >&2
d> cfg dock_proj_folder=$dock_proj_folder
d> cfg dock_data_folder=$dock_data_folder
d> cfg script_filepath=$0
d> cfg srt_1_filepath=$srt_1_filepath
d> cfg srt_2_filepath=$srt_2_filepath
EOD
fi

PATH=$PATH:$dock_proj_folder

#+--------------------+
#| normalize srt file |
#+--------------------+

if ! normalize 1 $srt_1_filepath
then
    exit 2
fi

if ! normalize 2 $srt_2_filepath
then
    exit 2
fi

exit 0

