
# SRT distance Metric

In this document we will exaplore a possible metric definition to measure the
similarity between two different subtitle files(SRT) for the same media content.
Let us assume we have a reference SRT file for a media content M and call it **R**. 
Let us also assume an SRT file which can be derived from spech to text conversion 
of the media content M. Let this genrated SRT file be **S**.

We use [Levenshtein](https://en.wikipedia.org/wiki/Levenshtein_distance) edit 
distance computation to figure our the optimal edits required to go from the 
reference R to S. Using the Levenshtein flow we determine the best alignment between
R and S such that maximum words will be matching.

We can generate the output as in **align_snippet.csv**. Each row of csv has following
entries:

1. ORG_TS: The time stamp as in original SRT file R.

2. ORG_WORD: Word seen in R.

3. LEV_OP: Edit operation required to go from R to S. 
    - '=' means matching
    - 'D' means delete to go from R to S i.e it is not present in S
    - 'I' means insert i.e. not present in R but present in S
    - 'R' means that corresponding word present in poth R and S but not matching

4. TRAN_TS: The time stamp as in SRT file S

5. TRAN_WORD: Word seen in S

6. TS_DIFF: (TRAN_TS - ORG_TS)

7. StopWord: Stop word as per NLP. Commonly occuring words which might not be 
greating adding to the semantic information

8. PartOfSpeech: Part of speech information like Noun, Pronoun, Verb, Adjective Adverb, Conjunction etc.

9. MaxScore: Maxscore that can be scored. Maxscore is given to words appearing 
   in the reference R.

10. GivenScore: Score given as per LEV_OP


## Strategies for Maxscore

1. 1 for non-stopwords and 0 for stop words
2. Different weght score for different parts of sppech. E.g. noun, verb, adjective, adverb get 2, other words get 1 and some let Det, Conj etc get 0

GivenScore is equal to Maxscore if LEV_OP is '=' otherwise 0


## Metric

**SrtSimilarity** = Sum(GivenScore)/Sum(MaxScore)

**TimeDeviation** = Sqrt(Sum((TS_DIFF - Mean(TS_DIFF))^2)/N)


## Process of validating the metric

