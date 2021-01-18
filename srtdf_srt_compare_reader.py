import os
import sys
import traceback

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, flush=True, **kwargs)
    #sys.stderr.flush()

class TimestampedWords(object):
    def __init__(self, module_name):
        self.m_mn       = module_name
        self.m_ts_words = []    # array of tuples (timestamp, word, SrtSegment)

    def add(self, ts_ms, word, srt_segment):
        self.m_ts_words.append((ts_ms, word, srt_segment))
        return len(self.m_ts_words)-1   # returns index 

    @property
    def words(self):
        return self.m_ts_words


class SrtSegment(object):
    def __init__(self, module_name, ts_words):
        self.m_mn       = module_name
        self.m_ts_words = ts_words
        self.m_state    = {}       

    #returns false at end of segment, true otherwise
    def parse(self, line):
        tokens = line.split()
        if (len(tokens) <= 1):
            return False

        mnemonic = tokens[1]
        if (mnemonic == 'I'):
            self.m_state["srt_index"] = int(tokens[2])
        elif (mnemonic == 'T'):
            self.m_state["begin_time_str"] = tokens[2]
            self.m_state["end_time_str"]   = tokens[4]
        elif (mnemonic == 'R'):
            self.m_state["begin_time_ms"]  = int(tokens[2])
            self.m_state["end_time_ms"]    = int(tokens[3])
            self.m_state["duration_ms"]    = int(tokens[4])
        elif (mnemonic == 'S'):
            self.m_state["srt_string"] = " ".join(tokens[2:])  
            # split and join ! what a waste !
        elif (mnemonic == 'W'):
            if (len(tokens) >= 4):
                i = self.m_ts_words.add(int(tokens[2]), tokens[3], self)
                if (not "begin_index" in self.m_state):
                    self.m_state["begin_index"] = i
                self.m_state["end_index"]   = i

    def is_valid(self):
        return ("srt_index"      in self.m_state and
                "begin_time_str" in self.m_state and
                "end_time_str"   in self.m_state and
                "begin_time_ms"  in self.m_state and
                "srt_string"     in self.m_state and
                "begin_index"    in self.m_state)

    def __str__(self):
        return str(self.m_state)

    @property
    def index(self):
        return self.m_state["srt_index"]

    def to_diff_format_string(self, prefix_str, indent_str):
        
        return """
%s%s I %d
%s%s T %s --> %s
%s%s R %d %d %s
%s%s S %s
""" % (prefix_str, 
       indent_str, 
       self.m_state["srt_index"],

       prefix_str, 
       indent_str, 
       self.m_state["begin_time_str"], 
       self.m_state["end_time_str"],

       prefix_str, 
       indent_str, 
       self.m_state["begin_time_ms"], 
       self.m_state["end_time_ms"],
       self.m_state["duration_ms"],

       prefix_str, 
       indent_str, 
       self.m_state["srt_string"])


class SrtSegments(object):
    def __init__(self, module_name, ts_words):
        self.m_mn               = module_name
        self.m_ts_words         = ts_words
        self.m_srt_segments     = []
        self.m_curr_srt_segment = None

    def parse(self, line):
        if (self.m_curr_srt_segment == None):
            self.m_curr_srt_segment = SrtSegment(self.m_mn, self.m_ts_words)

        if (self.m_curr_srt_segment.parse(line) == False):
            if (self.m_curr_srt_segment.is_valid()):
                self.m_srt_segments.append(self.m_curr_srt_segment)
            self.m_curr_srt_segment = None

    def segments(self):
        for i in range(len(self.m_srt_segments)):
            yield self.m_srt_segments[i]


class SrtCompareReader(object):

    def __init__(self, module_name):

        self.m_mn         = module_name

        self.m_ts_words_1 = TimestampedWords(module_name)
        self.m_ts_words_2 = TimestampedWords(module_name)

        self.m_segments_1 = SrtSegments(module_name, self.m_ts_words_1)
        self.m_segments_2 = SrtSegments(module_name, self.m_ts_words_2)


    def parse(self, line):

        if (line.startswith("> ")):
            self.m_segments_1.parse(line)
        else:
            self.m_segments_2.parse(line)


    @property
    def ts_words_in_1(self):
        return self.m_ts_words_1


    @property
    def ts_words_in_2(self):
        return self.m_ts_words_2


    @property
    def segments_in_1(self):
        return self.m_segments_1


    @property
    def segments_in_2(self):
        return self.m_segments_2


if __name__ == "__main__":

    #This program parses the output of
    #    python3 sstt_x_tabulate_srt.py \
    #    -c tl2 -i 15 -t org.srt transcribed.srt
    #See srt_compare.txt

    try :
        g_module_name  = os.path.basename(__file__)

        parser = SrtCompareReader(g_module_name)

        while True:
            try:
                line = input()
                #eprint(line)
                parser.parse(line)

            except EOFError:
                break

        eprint("#---[words in 1]---")
        eprint("")
        for i, v in enumerate(parser.ts_words_in_1.words):
            eprint("ts_words_1[%d] = (%d,%s,%s)" % (i, v[0], v[1], str(v[2])))

        eprint("")
        eprint("#---[segments in 1]---")
        eprint("")
        for seg in parser.segments_in_1.segments():
            eprint(str(seg))

        eprint("")
        eprint("#---[words in 2]---")
        eprint("")
        for i, v in enumerate(parser.ts_words_in_2.words):
            eprint("ts_words_2[%d] = (%d,%s,%s)" % (i, v[0], v[1], str(v[2])))

        eprint("")
        eprint("#---[segments in 2]---")
        eprint("")
        for seg in parser.segments_in_2.segments():
            eprint(str(seg))

    except:
        traceback.print_exc()
        sys.exit(1)


