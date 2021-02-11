#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

dir_path=$(readlink -e $(dirname $0))
mod_name=$(basename $0)
cfg_filepath=$dir_path/my_h_cfg.sh

#----[sources]---------------------------------------------------------------

source $cfg_filepath
source $host_proj_folder/common_bash_functions.sh

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

#----[main]------------------------------------------------------------------

#+---------------+
#| preprocessing |
#+---------------+

if [[ $# -ne 2 ]]
then
    error_message "two srt files needed for comparison"
    exit 1
fi

srt_1_filepath="$1"
srt_2_filepath="$2"

if [[ ! -f $srt_1_filepath ]]
then
    error_message "$srt_1_filepath not present"
    exit 1
fi

if [[ ! -f $srt_2_filepath ]]
then
    error_message "$srt_2_filepath not present"
    exit 1
fi

if ! mkdir -p $host_run_folder
then
    error_message "could not create folder $host_run_folder"
    exit 1
fi

cp $srt_1_filepath $host_run_folder
cp $srt_2_filepath $host_run_folder
cp $cfg_filepath   $host_run_folder
cp $dock_script_filepath $host_run_folder

#+-----------+
#| execution |
#+-----------+

docker run                      \
        --rm                    \
        --privileged            \
        --network host          \
        --name srt-diff-rel-c   \
        -v $host_run_folder:$dock_data_folder \
        -e MY_SRTDIFF_CFG_FILEPATH=$dock_data_folder/$(basename $cfg_filepath) \
        srt-diff-rel            \
        $dock_data_folder/$(basename $dock_script_filepath) \
            $dock_data_folder/$(basename $srt_1_filepath)   \
            $dock_data_folder/$(basename $srt_2_filepath) 
ret=$?

if ((ret != 0))
then
    exit $ret
fi

echo "$host_run_folder"

exit 0

