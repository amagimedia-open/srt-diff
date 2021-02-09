+----------------------------+
| What can this project do ? |
+----------------------------+

1. Create a 'srt compare' file given two srt files.
2. Arrive at the Levenshtein distance using the 'srt compare' file.
3. Format details of Levenshtein distance in csv format.

+---------------------+
| Run unit test cases |
+---------------------+

$ ./srtdf_h_build_dev_docker_image.sh
$ ./srtdf_h_run_utests_in_dev_docker.sh

+----------------------+
| Run srt_diff example |
+----------------------+

$ ./srtdf_h_build_rel_docker_image.sh
$ ./srt_diff_example.sh

+-----------+
| Resources |
+-----------+

http://www.let.rug.nl/~kleiweg/lev/
https://testanything.org/tap-specification.html

+--------------+
| More details |
+--------------+

+-----------------------+----------------------------------------------------+
|script                 |comment                                             |
+-----------------------+----------------------------------------------------+
|srt_diff.sh            |this is the main script that compares two srt files.|
|                       |run with -h option to get help.                     |
|                       |see srt_diff_example.sh for usage.                  |
|                       |                                                    |
|srtdf_lev_hist.sh      |this script generates a time range histogram using  |
|                       |the output of the srt_diff.sh script.               |
|                       |run with -h option to get help.                     |
|                       |see srt_diff_example.sh for usage.                  |
|                       |                                                    |
|srtdf_infer_endtime.sh |some srt files do not have an end time for one or   |
|                       |more segments. An example is:                       |
|                       |  1                                                 |
|                       |  00:00:05,672 --> --:--:--:--                      |
|                       |  BROUGHT THEIR A GAME                              |
|                       |this script can be used to patch the end time with  |
|                       |the help of the srtdf_utf8_base.sh script that      |
|                       |removes BOM and CRLF characters from a UTF-8 file.  |
|                       |see srt_diff_example.sh for usage.                  |
+-----------------------+----------------------------------------------------+

