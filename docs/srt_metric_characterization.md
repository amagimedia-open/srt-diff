# Process to characterize the SRT diff metric

This document intends to capture subjective test process to determine the correlation btween SRT-diff 
metric and the perceptual quality of the 'derived' subtitle against the original. There is a need for 
an objective measure to qualify the perceptual quality of 'derived' subtitles. In particular we could
'derive' subtitles from a media file using speech recognition services offered by AWS, GCP, IBM etc.

SRT-diff is a metric which gives a score between 0 to 1 for the similarity of subtitle files in SRT 
format. Also it captures temporal quality of the subtitles by binning  the deviation of 'word timestamp'
with respect to the original subtitle file.

## Process to capture subjective quality

## Test content preparation

1. Collect 10 minute clips along with their available(broadcast quality) subtitles. This collection
should belong to the following genres:
    - Documentary programs
    - Sports commentary
    - News
    - Movie clips
    - Reality shows

   A collection of 30 to 50 such clips and subtitles should be a good number

2. Clean the subtitles: This step removes additional annotations like "Narrator", "Scene description" which might
 be present in the original subtitles, but there is no way of 'deriving' it from the media file. Also it might be good
 to normalize the subtitles to all caps. This cleanup is most like a one time manual process.

3. Generate derived subtitles from each of the above clips say using GCP's speech to text service.

4. At this stage we should have 50 clips and 2 subtitles for each clip the original(A) and the derived one(B)

### Subjective test steps per user per test clip
1. User first sees the original clip A with subtitles
2. User is shown A and B corrresponding to the clip used in step 1 but in random order
3. User is expected to choose one of the following after viewing the random video
    - (c1) Perceptually same as the original 
    - (c2) There was slight degradation(e.g. grammatical) but largely still having all information
    - (c3) Loss of information 

**Notes**: 

- All above user playback should be with muted audio. Could this be a problem?
- Is duration 10 minutes too long?
- User should see all 3 videos. Leftmost is original, followed by random ordered A and B videos


## Derived Subjective Scrore

1. For each 'derived' clip derived subjective score is
    
    Sum(score(cx))/N
    
    with the sum on N users who have rated the 'derived' clip

## References

1. https://en.wikipedia.org/wiki/Codec_listening_test