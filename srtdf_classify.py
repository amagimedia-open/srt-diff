#+---------+
#| IMPORTS |
#+---------+

import os
import sys
import getopt
import traceback
import spacy

#+------------------+
#| GLOBAL VARIABLES |
#+------------------+

g_module_name = None
g_col_num = 5
g_input = None

#+----------------------+
#| FUNCTION DEFINITIONS |
#+----------------------+

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, flush=True, **kwargs)
    #sys.stderr.flush()

def usage():
    usage_str = f"""
NAME

    {g_module_name} - Classifies transcripted words using spacy

SYNOPSIS

    {g_module_name} [-h]

DESCRIPTION

    Classifies words under the TRAN_WORD column in the strlev.csv
    file (produced by srt_diff.sh) using the spacy package to produce
    two additional columns IS_STOP and PART_OF_SPEECH.

OPTIONS

    -i strlev_csv_filepath
    --input strlev_csv_filepath
       the location of the strlev.csv file.
       this is mandatory.

    -c tran_word_column_num
    --col-num tran_word_column_num
       an 1-offset integer that specifies the location of the 
       'transcribed word' column (TRANS_WORD).
       this is optional. default is {g_col_num}.

    -h
       this help.
       this is optional.
"""
    eprint(usage_str)


def emit_trans_phrase():

    header_line_seen = False
    words = []

    with open(g_input, "r") as fp:

        for line in fp:

            line = line.rstrip('\n')

            if (line.startswith("#")):
                continue

            if (not header_line_seen):
                header_line_seen = True
                continue

            fields = line.split(",")
            trans_word = fields[g_col_num-1]
            if (len(trans_word) > 0):
                words.append(trans_word)

    return " ".join(words)


def classify(phrase):

    nlp = spacy.load("en_core_web_sm")
    nlp_doc = nlp(phrase)

    return nlp_doc


def emit_classifiers(nlp_doc):

    header_line_seen = False
    i = 0

    with open(g_input, "r") as fp:

        for line in fp:

            line = line.rstrip('\n')

            if (line.startswith("#")):
                continue

            if (not header_line_seen):
                print(f"{line},NLP_WORD,IS_STOP,PART_OF_SPEECH")
                header_line_seen = True
                continue

            fields = line.split(",")
            trans_word = fields[g_col_num-1]

            if (len(trans_word) == 0):
                print(f"{line},,")
                continue

            nlp_token = nlp_doc[i]
            #if (trans_word != nlp_token.text):
            #    raise Exception(f"token mismatch. expected {trans_word} found {nlp_token.text}")

            print(f"{line},{nlp_token.text},{nlp_token.is_stop},{nlp_token.pos}")
            i = i + 1


#+------+
#| MAIN |
#+------+

if __name__ == '__main__':

    try:
        g_module_name  = os.path.basename(__file__)

        opts, args = \
            getopt.getopt(
                    sys.argv[1:], 
                    "i:c:h", 
                    [
                        "input=",
                        "col-num=",
                        "help" 
                    ])

        for o, v in opts:
            if o in ("-h", "--help"):
                usage()
                sys.exit(0)
            elif o in ("-i", "--input"):
                g_input = v
            elif o in ("-c", "--col-num"):
                g_col_num = int(v)

        if (g_input == None):
            eprint("-i option not specified")
            sys.exit(1)

        phrase = emit_trans_phrase ()
        print(phrase)

        print("----")

        #phrase = "I've done this before"
        #I've -> ive -> i ve

        nlp_doc = classify (phrase)
        for token in nlp_doc:
            print(token.text, token.pos_, token.tag_, token.dep_, token.is_stop)

        #emit_classifiers (nlp_doc)

    except:
        traceback.print_exc()
        sys.exit(1)
        
    sys.exit(0)

