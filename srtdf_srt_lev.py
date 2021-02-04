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

import srtdf_levenshtein as lev_m
import srtdf_srt_compare_reader as scr_m

#+------------------+
#| GLOBAL VARIABLES |
#+------------------+

g_module_name = None

#+-----------+
#| FUNCTIONS |
#+-----------+

def _eprint(*args, **kwargs):
    print(*args, file=sys.stderr, flush=True, **kwargs)
    #sys.stderr.flush()

def usage():
    format_str = """
NAME

    %s - compares srt files using levenshtein distance

SYNOPSIS

    %s [-h] 

DESCRIPTION

    This filter operates on the output of the
    'python3 sstt_x_tabulate_srt.py -c tl2' command line via stdin.

    The output on stdout is presented in the format:

    levenshtein_distance
    #--details--                                   ---+
    FROM_TS,FROM_WORD,FROM_POS,FROM_ISSTOP,LEV_OP,TO_TS,TO_WORD,TO_POS,TO_ISSTOP,TS_DIFF
    .......,.........,......,.....,.......,.......    |
    .......,.........,......,.....,.......,.......    | this is output
    > lines from the input                            | only if -l 
    < lines from the input                            | option is 
    .......,.........,......,.....,.......,.......    | specified
    .......,.........,......,.....,.......,.......    |
    #--metrics--                                      |
    min timeDiffMs              TODO                  |
    max timeDiffMs              TODO                  |
    av  timeDiffMs              TODO                  |
    std standardDeviation       TODO                  |
                                                   ---+

    The format in the 'details' section is as follows:
    FROM_TS and FROM_WORD refer to entries marked with '>' against each 
    line in stdin.
    TO_TS and TO_WORD refer to entries marked with '<' against each line 
    in stdin.
    LEV_OP is one of '=','R','D' and 'I' signifying the operation needed
    to convert FROM_WORD to TO_WORD. 
        '=' => same. noop.
        'R' => replace.
        'D' => delete.
        'I' => insert.
    TS_DIFF represents diff(FROM_TS, TO_TS)

OPTIONS

    -d
       print debug information on stderr.
       this is optional.

    -l
       lengthy output consisting of details.
       this is optional.

    -C "col1_name,col2_name,..."
       a string specifying the column header names.
       used if (-v value) >= 1.
       this is optional.
       default is "FROM_TS,FROM_WORD,FROM_POS,FROM_ISSTOP,LEV_OP,TO_TS,TO_WORD,TO_POS,TO_ISSTOP,TS_DIFF"

    -h
       this help.
       this is optional.
"""
    usage_str = format_str % (g_module_name, g_module_name)
    _eprint(usage_str)


def parse_input(srt_parser, options):

    line_num = 0


    while True:
        try:
            line_num = line_num + 1
            line = input()
            if (options.debug):
                _eprint("%s:debug:parsing line %d:%s" % \
                        (g_module_name, line_num, line))
            srt_parser.parse(line)

        except EOFError:
            if (options.debug):
                _eprint("%s:debug:%s" % (g_module_name, "end of input seen"))
            break


#+---------+
#| CLASSES |
#+---------+

class Options(object):
    def __init__(self, module_name):
        self.m_mn      = module_name
        self.m_debug   = False
        self.m_lengthy = False
        self.m_dump_ts_words = False
        self.m_dump_input    = False
        self.m_def_col_names = "FROM_TS,FROM_WORD,FROM_POS,FROM_ISSTOP,LEV_OP,TO_TS,TO_WORD,TO_POS,TO_ISSTOP,TS_DIFF"
        self.m_col_names     = self.m_def_col_names

    @property
    def debug(self):
        return self.m_debug

    @debug.setter
    def debug(self, v):
        self.m_debug = v

    @property
    def lengthy(self):
        return self.m_lengthy

    @lengthy.setter
    def lengthy(self, v):
        self.m_lengthy = v

    @property
    def col_names(self):
        return self.m_col_names

    @col_names.setter
    def col_names(self, str):
        cols = str.split(",")
        if (len(cols) != 10):
            err_str = "%s: mismatch in number of column names. expected %d found %d" % (self.m_mn, 10, len(cols))
            raise Exception (err_str)
        self.m_col_names = str

    def parse_cmdline(self):
        opts, args = \
            getopt.getopt(sys.argv[1:], 
                    "lC:dh", 
                    [
                      "lengthy",
                      "col-names=",
                      "debug",
                      "help"
                    ])

        for o, v in opts:
            if o in ("-h", "--help"):
                usage()
                sys.exit(0)
            elif o in ("-l", "--lengthy"):
                options.lengthy = True
            elif o in ("-C", "--col-names"):
                options.col_names = v
            elif o in ("-d", "--debug"):
                options.debug = True

    #https://dbader.org/blog/python-repr-vs-str

    def __str__(self):
        ret = { 
                "--lengthy"   : self.m_lengthy,
                "--col-names" : self.m_col_names,
                "--debug"     : self.m_debug
              }
        return str(ret)


class SrtSegmentInfoDumper(object):

    def __init__(self, module_name, prefix_str, num_indent_spaces):

        self.m_mn = module_name
        self.m_prev_index = -1
        self.m_prefix_str = prefix_str
        self.m_indent_str = ' ' * num_indent_spaces

    def dump(self, ssi):  # ssi => srt_segment_info

        if (ssi.index != self.m_prev_index):
            print(ssi.to_diff_format_string(self.m_prefix_str, self.m_indent_str))
            self.m_prev_index = ssi.index


class LevRecordDumper(object):

    def __init__(self, module_name, col_names):

        self.m_mn = module_name
        self.m_ssid_1 = SrtSegmentInfoDumper(module_name, ">", 0)
        self.m_ssid_2 = SrtSegmentInfoDumper(module_name, "<", 15)
        self.m_dump_op_fnxs = \
                {
                    '=' : LevRecordDumper.dump_match_or_replace_record,
                    'R' : LevRecordDumper.dump_match_or_replace_record,
                    'D' : LevRecordDumper.dump_delete_record,
                    'I' : LevRecordDumper.dump_insert_record
                }

        print(col_names)


    def dump(self, op_rec):
        #
        # print("FROM_TS,FROM_WORD,FROM_POS,FROM_ISSTOP,LEV_OP,TO_TS,TO_WORD,TO_POS,TO_ISSTOP,TS_DIFF")
        #
        # type(op_rec) is as follows
        #   (op, item_in_1|None, item_in_2|None)
        #
        # type(item) is as follows 
        #   (timestampms,word,pos,isstop,srtsegment)
        #
        # an example of srtsegment is as follows
        #
        #   {'srt_index': 1, 'begin_time_str': '00:00:01,600', 'end_time_str': '00:00:02,684', 'begin_time_ms': 1600, 'end_time_ms': 2684, 'duration_ms': 1084, 'srt_string': 'Mr Stark, hi there.', 'begin_index': 0, 'end_index': 3})
        #

        op = op_rec[0]
        (self.m_dump_op_fnxs[op])(self, op_rec)


    def dump_match_or_replace_record(self, op_rec):

        op        = op_rec[0]
        item_in_1 = op_rec[1]
        item_in_2 = op_rec[2]

        ts_in_1    = item_in_1[0]
        word_in_1  = item_in_1[1]
        pos_in_1   = item_in_1[2]
        istop_in_1 = item_in_1[3]
        ssi_in_1   = item_in_1[4]

        ts_in_2    = item_in_2[0]
        word_in_2  = item_in_2[1]
        pos_in_2   = item_in_2[2]
        istop_in_2 = item_in_2[3]
        ssi_in_2   = item_in_2[4]

        ts_diff = abs(ts_in_1 - ts_in_2)

        self.m_ssid_1.dump(ssi_in_1)
        self.m_ssid_2.dump(ssi_in_2)

        print(f"{ts_in_1},{word_in_1},{pos_in_1},{istop_in_1},"
              f"{op},"
              f"{ts_in_2},{word_in_2},{pos_in_2},{istop_in_2},"
              f"{ts_diff}")


    def dump_delete_record(self, op_rec):

        op        = op_rec[0]
        item_in_1 = op_rec[1]

        ts_in_1    = item_in_1[0]
        word_in_1  = item_in_1[1]
        pos_in_1   = item_in_1[2]
        istop_in_1 = item_in_1[3]
        ssi_in_1   = item_in_1[4]

        self.m_ssid_1.dump(ssi_in_1)

        print(f"{ts_in_1},{word_in_1},{pos_in_1},{istop_in_1},"
              f"{op},"
              f",,,,")


    def dump_insert_record(self, op_rec):

        op        = op_rec[0]
        item_in_2 = op_rec[2]

        ts_in_2    = item_in_2[0]
        word_in_2  = item_in_2[1]
        pos_in_2   = item_in_2[2]
        istop_in_2 = item_in_2[3]
        ssi_in_2   = item_in_2[4]

        self.m_ssid_2.dump(ssi_in_2)

        print(f",,,,"
              f"{op},"
              f"{ts_in_2},{word_in_2},{pos_in_2},{istop_in_2},")


#+------+
#| MAIN |
#+------+

if __name__ == '__main__':

    try:
        g_module_name  = os.path.basename(__file__)

        #
        # collect command line options
        #

        options = Options(g_module_name)
        options.parse_cmdline()
        if (options.debug):
            _eprint("%s:debug:options:%s" %
                    (g_module_name, str(options)))


        #
        # parse srt diff presented via stdin
        #

        if (options.debug):
            _eprint("%s:debug:%s" %
                    (g_module_name, 
                     "starting to read lines from stdin"))

        srt_parser = scr_m.SrtCompareReader(g_module_name)
        parse_input(srt_parser, options)

        if (options.debug):
            _eprint("%s:debug:%s" %
                    (g_module_name,
                     "completed reading lines from stdin"))

        #
        # calculate levenshtein distance
        #

        if (options.debug):
            _eprint("%s:debug:%s" %
                    (g_module_name, 
                     "starting to calculate Levenshtein distance"))

        lev = lev_m.Levenshtein(
                g_module_name, 
                srt_parser.ts_words_in_1.words,
                srt_parser.ts_words_in_2.words,
                lambda e1, e2 : e1[1] == e2[1])
        lev_dist = lev.distance(options.debug)
        print("%d" % lev_dist)

        if (options.debug):
            _eprint("%s:debug:%s" %
                    (g_module_name, 
                     "completed calculation of Levenshtein distance"))

        #
        # dump details and metrics
        #

        if (options.lengthy):

            print("#--details--")
            lev_rd = LevRecordDumper(g_module_name, options.col_names)
            for op_rec in lev.walk():
                lev_rd.dump(op_rec)

            print("#--metrics--")

    except:
        traceback.print_exc()
        sys.exit(1)
        
    sys.exit(0)

