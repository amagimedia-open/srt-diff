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
g_col_num = 5       # TRAN_WORD column number in srtlev.csv
g_input = None
g_model_name = "en_core_web_sm"
g_debug = False

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

    This program when presented with a strlev.csv file (that is
    the output of the srt_diff.sh program) adds two more 
    columns of information IS_STOP,PART_OF_SPEECH and dumps 
    the output on stdout.

OPTIONS

    -i strlev_csv_filepath
    --input strlev_csv_filepath
       the location of the strlev.csv file.
       this is mandatory.

    -m "model_name"
    --model-name "model_name"
       the spacy model to be used to perform the classification.
       this is optional. default is {g_model_name}.

    -c tran_word_column_num
    --col-num tran_word_column_num
       an 1-offset integer that specifies the location of the 
       'transcribed word' column (TRANS_WORD).
       this is optional. default is {g_col_num}.

    -d
       debug output is dumped to stderr.
       this is optional.

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

    line_num = 0
    header_line_seen = False
    token_index = 0

    with open(g_input, "r") as fp:

        for line in fp:

            line_num = line_num + 1

            line = line.rstrip('\n')

            if (line.startswith("#")):
                continue

            if (not header_line_seen):
                print(f"{line},IS_STOP,PART_OF_SPEECH")
                header_line_seen = True
                continue

            fields = line.split(",")
            trans_word = fields[g_col_num-1]

            if (len(trans_word) == 0):
                print(f"{line},,")
                continue

            nlp_token = nlp_doc[token_index]
            nlp_text  = nlp_token.text.translate({ord(','): None})
                #https://www.journaldev.com/23674/python-remove-character-from-string

            if (g_debug):
                eprint (f"line_num={line_num}, trans_word={trans_word}, token_text={nlp_token.text}, final_text={nlp_text}")

            if (trans_word != nlp_text):
                raise Exception(f"token mismatch. expected {trans_word} found {nlp_text} at line {line_num}")

            print(f"{line},{nlp_token.is_stop},{nlp_token.pos}")
            token_index = token_index + 1


#+------+
#| MAIN |
#+------+

if __name__ == '__main__':

    try:
        g_module_name  = os.path.basename(__file__)

        opts, args = \
            getopt.getopt(
                    sys.argv[1:], 
                    "i:c:m:dh", 
                    [
                        "input=",
                        "col-num=",
                        "model-name=",
                        "debug",
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
            elif o in ("-m", "--model-name"):
                g_model_name = v
            elif o in ("-d", "--debug"):
                g_debug = True

        if (g_input == None):
            eprint("-i option not specified")
            sys.exit(1)

        phrase = emit_trans_phrase ()
        if (g_debug):
            eprint(f"phrase={phrase}")

        nlp_doc = classify (phrase)
        if (g_debug):
            for token in nlp_doc:
                eprint(token.text, token.pos_, token.tag_, token.dep_, token.is_stop)

        emit_classifiers (nlp_doc)

    except:
        traceback.print_exc()
        sys.exit(1)
        
    sys.exit(0)

