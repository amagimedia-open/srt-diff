+---------------------+
| Run unit test cases |
+---------------------+

$ ./srtdf_h_build_docker_image.sh
$ ./srtdf_h_run_utests_in_docker.sh

+------+
| Misc |
+------+

https://www.arj.no/2018/05/18/trimvideo/
https://stackoverflow.com/questions/18444194/cutting-the-videos-based-on-start-and-end-time-using-ffmpeg
ffmpeg -i ../../../samples/bein_1/beIN_Osasuna_Barcelona.mp4 -ss 00:00:00 -to 00:00:10 -c:v copy -c:a copy test.mp4
    
+-----------+
| Resources |
+-----------+

http://www.let.rug.nl/~kleiweg/lev/
https://medium.com/better-programming/the-beginners-guide-to-similarity-matching-using-spacy-782fc2922f7c
http://annameier.net/spacy-no-internet/
https://tinystats.github.io/teacups-giraffes-and-statistics/04_variance.html
https://testanything.org/tap-specification.html
https://node-tap.org/tap-protocol/
