#+---------+
#| IMPORTS |
#+---------+

import os
import sys
import traceback
import pysrt
import getopt
import tempfile
import re

#+------------------+
#| GLOBAL VARIABLES |
#+------------------+

g_module_name = None

#+----------------------+
#| FUNCTION DEFINITIONS |
#+----------------------+

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, flush=True, **kwargs)
    #sys.stderr.flush()

def usage():
    format_str = """
NAME

    %s - Creates a 'srt compare' file given two srt files.

SYNOPSIS

    %s [-i num_spaces] [-W] [-t time_mode] [-L] [-P]
       srt/file/path1 srt/file/path2

DESCRIPTION

    Displays the srt file in a column format.
    Lines from the first file are displayed with the character '>' in the
    first column.
    Lines from the second file are displayed with the character '<' in the
    first column.

    The mnemonics used are
    'I' -> srt_index
    'T' -> time range
    'D' -> time range in milliseconds and duration
    'S' -> string from the original occuring in the time range stripped
           of the newline
    'W' -> the time in milliseconds at which the word occurs in the string

OPTIONS

    -i num_spaces_to_indent_second_file
       the number of spaces of padding with which lines in the second file
       are indented by.
       this is optional. default is 20.

    -W
       suppress time-of-occurange words display. 
       the -t, -l and -p options are ignored here.
       this is optional. default is to display time and occurance
       of each word.

    -t time_mode
       specifies the method to be used to arrive at the time-of-occurance
       of each word.
       this must be one of the following:
       av -> average of the time range in which the word occurs
       wc -> word count of the time range in which the word occurs is used
       cc -> character count of the time range in which the word occurs is used
       this is optional. default is 'cc'.

    -L
       suppress conversion of words to lower case.
       this is optional. default is to convert words to lower case.

    -P
       suppress removal of punctuations in/across words.
       this is optional. default is to remove punctuations.

    -h
       this help.
       this is optional.
"""
    usage_str = format_str % (g_module_name, g_module_name)
    eprint(usage_str)

#+-------------------+
#| CLASS DEFINITIONS |
#+-------------------+

class Options(object):

    TO_AV = 1
    TO_WC = 2
    TO_CC = 3

    def __init__(self, module_name):
        self._mn       = module_name

        self._prefix_1     = "> "
        self._prefix_2     = "< "
        self._indent_2_by  = 20
        self._too          = True
        self._too_mode     = Options.TO_CC
        self._to_lower     = True
        self._remove_punct = True
        self._debug        = False

        self._srt_filepath_1 = None
        self._srt_filepath_2 = None

    @property
    def prefix_1(self):
        return self._prefix_1

    @property
    def prefix_2(self):
        return self._prefix_2

    @property
    def indent_2_by(self):
        return self._indent_2_by

    @indent_2_by.setter
    def indent_2_by(self, n):
        self._indent_2_by = n

    @property
    def too(self):
        return self._too

    @too.setter
    def too(self, b):
        self._too = b

    @property
    def too_mode(self):
        return self._too_mode

    @too_mode.setter
    def too_mode(self, v):
        if (v == "av"):
            self._too_mode = Options.TO_AV
        elif (v == "wc"):
            self._too_mode = Options.TO_WC
        elif (v == "cc"):
            self._too_mode = Options.TO_CC
        else:
            err_str = "%s: invalid option value %s" % (self._mn, v)
            raise Exception (err_str)

    @property
    def to_lower(self):
        return self._to_lower

    @to_lower.setter
    def to_lower(self, b):
        self._to_lower = b

    @property
    def remove_punct(self):
        return self._remove_punct

    @remove_punct.setter
    def remove_punct(self, b):
        self._remove_punct = b

    @property
    def debug(self):
        return self._debug

    @debug.setter
    def debug(self, b):
        self._debug = b

    def check_filepath(filepath):
        if (not os.path.isfile(filepath)):
            err_str = "%s: filepath %s not found" % (self._mn, str)
            raise Exception (err_str)

    @property
    def srt_filepath_1(self):
        return self._srt_filepath_1

    @srt_filepath_1.setter
    def srt_filepath_1(self, filepath):
        Options.check_filepath(filepath)
        self._srt_filepath_1 = filepath

    @property
    def srt_filepath_2(self):
        return self._srt_filepath_2

    @srt_filepath_2.setter
    def srt_filepath_2(self, filepath):
        Options.check_filepath(filepath)
        self._srt_filepath_2 = filepath

    def parse_cmdline(self):
        opts, args = \
            getopt.getopt(sys.argv[1:], 
                    "i:Wt:LPdh", 
                          [
                           "indent-2-by=",
                           "suppress-words",
                           "too-mode=",
                           "suppress-to-lower",
                           "suppress-remove-punct",
                           "debug",
                           "help"
                          ])

        for o, v in opts:
            if o in ("-h", "--help"):
                usage()
                sys.exit(0)
            elif o in ("-i", "--indent-2-by"):
                options.indent_2_by = int(v)
            elif o in ("-W", "--suppress-words"):
                options.too = False
            elif o in ("-t", "--too-mode"):
                options.too_mode = v
            elif o in ("-L", "--suppress-to-lower"):
                options.to_lower = False
            elif o in ("-P", "--suppress-remove-punct"):
                options.remove_punct = False
            elif o in ("-d", "--debug"):
                options.debug = True

        if (len(args) != 2):
            err_str = "%s: two srt filepaths are expected" % (g_module_name)
            raise Exception (err_str)
        self.srt_filepath_1 = args[0]
        self.srt_filepath_2 = args[1]

    #https://dbader.org/blog/python-repr-vs-str

    def __str__(self):
        ret = { 
                "indent"       : options.indent_2_by,
                "too"          : options.too,
                "too-mode"     : options.too_mode,
                "to-lower"     : options.to_lower,
                "remove-punct" : options.remove_punct,
                "debug"        : options.debug
              }
        return str(ret)


def SubRipTime_2_ms(srt_time):
    return  (srt_time.hours    * 3600 + 
             srt_time.minutes  * 60   +
             srt_time.seconds) * 1000 + \
             srt_time.milliseconds


def dump_srt_item(item, prefix_str, lpad_str, options):

    s = str(item.index)
    print("%sI %s%s" % (prefix_str, lpad_str, s))

    s1 = str(item.start)
    s2 = str(item.end)
    print("%sT %s%s --> %s" % (prefix_str, lpad_str, s1, s2))

    range_start_ms = SubRipTime_2_ms(item.start)
    range_end_ms   = SubRipTime_2_ms(item.end)
    range_ms       = (range_end_ms - range_start_ms)
    print("%sR %s%d %d %d" % (prefix_str, lpad_str, range_start_ms, range_end_ms, range_ms))

    s = re.sub('\n', ' ', item.text)
    print("%sS %s%s" % (prefix_str, lpad_str, s))

    if (options.too):
        #--- dump words ---

        words     = s.split()
        num_words = len(words)
   
        if (options.debug):
            print(f"words={words},num_words={num_words}")
           
        if (options.too_mode == Options.TO_AV):
            range_av_ms = (range_start_ms + range_end_ms) / 2
        elif (options.too_mode == Options.TO_WC):
            word_time_width_ms = range_ms / num_words
        else: #TO_CC
            total_chars = 0
            for w in words:
                total_chars = total_chars + len(w)
            total_chars = total_chars + num_words # (num_words -> spaces)
            char_time_width_ms = range_ms / total_chars

        next_offset_ms = range_start_ms
        for w in words:
            #https://www.geeksforgeeks.org/python-remove-punctuation-from-string/
            #punc = '''!()-[]{};:'"\, <>./?@#$%^&*_~'''
            #cw = re.sub(r'[^\w\s]','',w)
            #cw = re.sub(r'[!\-;:",.?]','',w)
            
            cw = w
            if (options.remove_punct):
                cw = re.sub(r'[^\w\s]','',cw)
            if (options.to_lower):
                cw = cw.lower()

            if (options.too_mode == Options.TO_AV):
                print("%sW %s%d %s" % (prefix_str, lpad_str, range_av_ms, cw))
            elif (options.too_mode == Options.TO_WC):
                print("%sW %s%d %s" % (prefix_str, lpad_str, next_offset_ms, cw))
                next_offset_ms  = next_offset_ms + word_time_width_ms
            else: #TO_CC
                print("%sW %s%d %s" % (prefix_str, lpad_str, next_offset_ms, cw))
                curr_word_len      = len(w) + 1
                                     # ^^^ note its w not cw, 1 for space
                curr_word_width_ms = curr_word_len  * char_time_width_ms
                next_offset_ms     = next_offset_ms + curr_word_width_ms

    print("%s" % (prefix_str))
    
#+------+
#| MAIN |
#+------+

if __name__ == '__main__':

    try:
        g_module_name  = os.path.basename(__file__)
        options        = Options(g_module_name)

        options.parse_cmdline()

        lpad_str = ' ' * options.indent_2_by

        items_in_1 = pysrt.open(options.srt_filepath_1)
        items_in_2 = pysrt.open(options.srt_filepath_2)

        num_items_in_1 = len(items_in_1)
        num_items_in_2 = len(items_in_2)

        j = 0

        for i in range(num_items_in_1):

            dump_srt_item(items_in_1[i], options.prefix_1, "", options)

            e_1_ms = SubRipTime_2_ms(items_in_1[i].end)
            #print ("e_1_ms", e_1_ms)

            while (j < num_items_in_2):

                b_2_ms = SubRipTime_2_ms(items_in_2[j].start)
                #print ("b_2_ms", b_2_ms)

                if (b_2_ms > e_1_ms):
                    break

                dump_srt_item(items_in_2[j], options.prefix_2, lpad_str, options)

                j = j + 1

        while (j < num_items_in_2):

            dump_srt_item(items_in_2[j], options.prefix_2, lpad_str, options)
            j = j + 1

    except:
        traceback.print_exc()
        sys.exit(1)
        
    sys.exit(0)

