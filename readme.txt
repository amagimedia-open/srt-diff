+----------------------------+
| What can this project do ? |
+----------------------------+

(a) infer end time of srt file where the end time is not present. example:
    1
    00:00:05,672 --> --:--:--:--
    BROUGHT THEIR A GAME

(b) Given two srt files arrive at a distance (levenshtein) between them.

(c) Dump a histogram of the levenshtein details.


+---------------------+
| Project composition |
+---------------------+

The project consists of many scripts that have to be run inside a docker.
The main ones are

(a) srtdf_infer_endtime.sh
(b) srt_diff.sh
(c) srtdf_lev_hist.sh

Details of command line options can be got by invoking the -h option for
each of these scripts.

+---------------+
| Example usage |
+---------------+

First make sure that the docker image is built through
$ ./srtdf_h_build_rel_docker_image.sh

An example is provided that performs a srt_diff of two srt files.
The example consists of three files:

my_h_cfg.sh     - the configuration file used by 
                  my_h_srtdiff.sh and my_d_srtdiff.sh
my_h_srtdiff.sh - the script to be run on the host
my_d_srtdiff.sh - the script that is run inside the docker

Run this example as follows:
$ ./my_h_srtdiff.sh foo.srt boo.srt 

This run will generate intermediate and output files in the
host_run_folder (see my_h_cfg.sh). They are as follows:

+------------------+------------------------------------------------+
| Filename         |  Comment                                       |
+------------------+------------------------------------------------+
| my_h_cfg.sh      |  The configuration file                        |
| my_d_srtdiff.sh  |  The script that runs inside the docker        |
+------------------+------------------------------------------------+
| foo.srt          |  The first srt file                            |
| boo.srt          |  The second srt file                           |
+------------------+------------------------------------------------+
| 1.norm.srt       |  The first srt file stripped of UTF-8 BOM      |
|                  |  and '\r' characters                           |
| 2.norm.srt       |  The second srt file stripped of UTF-8 BOM     |
|                  |  and '\r' characters                           |
+------------------+------------------------------------------------+
| 1.iet.srt        |  The first srt file with inferred end times    |
| 1.iet.dbg.csv    |  Debug details while arriving at 1.iet.srt     |
| 2.iet.srt        |  The second srt file with inferred end times   |
| 2.iet.dbg.csv    |  Debug details while arriving at 2.iet.srt     |
+------------------+------------------------------------------------+
| srtcomp.txt      |  Contains 'visual' srt comparison of the files |
| srtcomplev.txt   |  srtcomp.txt with levenshtein details          |
| srtlev.csv       |  levenshtein details in csv format             |
| levdist.txt      |  the levenshtein distance                      |
+------------------+------------------------------------------------+
| levhist.csv      |  histogram of levenshtein distances in         |
|                  |  srtlev.csv                                    |
+------------------+------------------------------------------------+

