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
