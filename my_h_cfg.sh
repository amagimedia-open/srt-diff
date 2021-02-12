#+-----------------------------+
#| HOST FILES AND FOLDER PATHS |
#+-----------------------------+

host_proj_folder=$PWD
    # location of the srt-diff git clone

host_run_folder="$PWD/my_h_srtdiff_runs/$(date +%Y_%m_%d_%H_%M_%S_%N)"
    # location of the folder in which the intermediate and output
    # files will be stored

dock_script_filepath="$host_proj_folder/my_d_srtdiff.sh"
    # location of the script that will run inside the srt-diff-rel docker

#+-------------------------------+
#| DOCKER FILES AND FOLDER PATHS |
#+-------------------------------+

dock_data_folder="/data"    
    # folder in the docker that is mapped to host_run_folder via 
    # -v option of docker run
    # DONT MODIFY THIS

dock_proj_folder="/srt-diff"
    # the project location inside the docker
    # see srtdf_h_rel_dockerfile.txt
    # DONT MODIFY THIS ENTRY UNLESS srtdf_h_rel_dockerfile.txt HAS CHANGED

#+-------------------------------+
#| SRT-DIFF UTILITIES PARAMETERS |
#+-------------------------------+
    
debug=1
    # whether debug output (on stderr) is required

infer_end_time_tolerance=1300
    # value of the -t option of srtdf_infer_endtime.sh

infer_end_time_wpm=250
    # value of the -w option of srtdf_infer_endtime.sh


