#!/bin/bash

# http://psy.swansea.ac.uk/staff/carter/Misc/unicode.htm#:~:text=UCS%2D2%20is%20obsolete%20and,code%20points%20for%20most%20characters.
# http://thegreyblog.blogspot.com/2010/09/shell-script-to-find-and-remove-bom.html

set -u
#set -x

#----[temp files and termination]--------------------------------------------

TERMINATED=0

function fnxOnEnd
{
    ((TERMINATED==0)) && { rm -f $TMP1 $TMP2; }
    TERMINATED=1
}

TMP1=`mktemp`
TMP2=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[globals]------------------------------------------------------------------------

DIRNAME=$(readlink -e $(dirname $0))
MODNAME=$(basename $0)

#----[sources]---------------------------------------------------------------

source $DIRNAME/common_bash_functions.sh

#----[options]---------------------------------------------------------------

OPT_WPM=150
OPT_TOLERANCE_MS=1000
OPT_DEBUG=0
OPT_SRT_FILEPATH=""

#----[helper functions]------------------------------------------------------

function usage
{
    cat <<EOD
NAME

    $MODNAME - Infers the end time of each srt entry
                   
SYNOPSIS

    $MODNAME [-w words_per_minute] [-h]
             
DETAILS

    Some srt files can contain an entry such as 

    1
    00:00:05,672 --> --:--:--:--
    BROUGHT THEIR A GAME

    that dont have an end time !

    This script infers an end time for entries that do not have them.
    This script uses a default of 150 wpm (words per minute) to arrive
    at the end time.

    The Average speech rates are as follows:

    Presentations:  between 100 - 150 wpm for a comfortable pace
    Conversational: between 120 - 150 wpm
    Audiobooks:     between 150 - 160 wpm, which is the upper range that people 
                    comfortably hear and vocalise words
    Radio hosts and podcasters: between 150 - 160 wpm
    Auctioneers:    can speak at about 250 wpm
    Commentators:   between 250- 400 wpm

    See https://virtualspeech.com/blog/average-speaking-rate-words-per-minute#:~:text=According%20to%20the%20National%20Center,podcasters%2C%20the%20wpm%20is%20higher 
    for more details.

    The Input srt file has to be 'filtered' through srtdf_utf8_base.sh
    and presented via stdin.
    The modified srt is presented via stdout.

    A note on extrapolation and tolerance.

    * Extrapolation is the act of arriving at an end time from the beginning
      time using WPM (words per minute).

    * Tolerance cand be explained using the following example.

      Consider two input segments 10 and 11

      10
      00:00:05,672 --> --:--:--:--
      BROUGHT THEIR A GAME

      11
      00:00:06,100 --> --:--:--:--
      A THROUGH UNDERSTANDING

      Let us say that the extrapolated end time for segment 10 is 
      00:00:06,700. We see that this is greater than the beginning
      time for the segment 11 i.e. 00:00:06,100

      A tolerance of 1000 implies that the end time of a previous segment
      can exceed the beginning of the next segment by an amount not greater
      than 1000 ms and would lead to truncation of the extrapolated output
      as follows:

      10
      00:00:05,672 --> 00:00:06,100
      BROUGHT THEIR A GAME

      11
      00:00:06,100 --> --:--:--:--
      A THROUGH UNDERSTANDING

      If the tolerance is set to 500, the script will exit as 
      (00:00:06,700 - 00:00:06,100) > 500 ms.


OPTIONS

    -w words_per_minute
       This is optional. default is $OPT_WPM.

    -t tolerance_ms
       this is optional. default is $OPT_TOLERANCE_MS.

    -d
       Debug output on stderr.
       This is optional.

    -h
       Displays this help and quits.
       This is optional.

EXAMPLE

    srtdf_utf8_base.sh foo.srt | $MODNAME

EOD
}

#----------------------------------------------------------------------------
# MAIN
#----------------------------------------------------------------------------

#+---------------------+
#| argument processing |
#+---------------------+

TEMP=`getopt -o "w:t:dh" -n "$0" -- "$@"`
eval set -- "$TEMP"

while true 
do
	case "$1" in
        -w) OPT_WPM=$2; shift 2;;
        -t) OPT_TOLERANCE_MS=$2; shift 2;;
        -d) OPT_DEBUG=1; shift 1;;
        -h) usage; exit 0;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

#+-------------------------+
#| generate histogram data |
#+-------------------------+

gawk -v v_wpm=$OPT_WPM \
     -v v_tolerance_ms=$OPT_TOLERANCE_MS \
     -v v_debug=$OPT_DEBUG \
'
    BEGIN \
    {
        EOS_SEEN   = 1          # EOS => END OF SEGMENT (index + time range + phrase(s))
        INDEX_SEEN = 2
        TIME_RANGE_SEEN = 3
        #PHRASES

        state = EOS_SEEN
        error = 0
        line_num = 0

        curr["index"] = 0
        curr["time_range_good"] = 0
        curr["begin_time_str"] = ""
        curr["begin_time_ms"] = 0
        curr["comp_end_time_str"] = ""
        curr["comp_end_time_ms"] = 0
        curr["end_time_str"] = ""
        curr["end_time_ms"] = 0
        curr["end_truncated"] = 0
        curr["phrase_line_count"] = 0
        curr["phrase_word_count"] = 0
        curr["duration_ms"] = 0

        prev["index"] = -1

        phrase_lines[0] = ""    # read as prev_phrase_lines

        if (v_debug)
            dump_debug_header()
    }

    {
        ++line_num

        if (state == EOS_SEEN)
        {
            if (is_empty_line())
                next

            copy_array(curr, prev)
            reset_array(curr)

            if (! is_srt_index())
            {
                printf "at line %d : expecting index", line_num > "/dev/stderr"
                error = 1
                exit (1)
            }

            curr["index"] = int($0)
            state = INDEX_SEEN
            next
        }

        if (state == INDEX_SEEN)
        {
            if (! is_srt_time($1))
            {
                printf "at line %d : invalid begin time", line_num > "/dev/stderr"
                error = 1
                exit (1)
            }

            if (is_srt_time($3))
                curr["time_range_good"] = 1

            curr["begin_time_str"]    = $1
            curr["begin_time_ms"]     = srt_time_2_ms(curr["begin_time_str"])

            curr["end_time_str"]      = $3
            curr["end_time_ms"]       = srt_time_2_ms(curr["end_time_str"])

            curr["comp_end_time_str"] = curr["end_time_str"]
            curr["comp_end_time_ms"]  = curr["end_time_ms"]

            if (prev["index"] > 0)
            {
                infer_and_dump_prev_segment()
                delete phrase_lines
            }

            state = TIME_RANGE_SEEN
            next
        }

        if (state == TIME_RANGE_SEEN)
        {
            if (! is_empty_line())
            {
                phrase_lines[curr["phrase_line_count"]] = $0

                ++curr["phrase_line_count"]

                n_words = split($0, t_arr, /[ \t][ \t]*/)
                curr["phrase_word_count"] += n_words

                next
            }

            # we have seen a blank line here and thus
            # we have arrived at the end of a segment

            if (! curr["time_range_good"])
                set_curr_end_time_str()

            state = EOS_SEEN
            next
        }
    }

    END \
    {
        if (error)
            exit(1)

        if (curr["index"] > 0)
        {
            if (! curr["time_range_good"])
                set_curr_end_time_str()
            infer_and_dump_curr_segment()
        }
    }

    function is_empty_line()
    {
        return ($0 ~ /^[ \t]*$/)
    }

    function is_srt_index()
    {
        return ($0 ~ /^[0-9][0-9]*$/)
    }

    function is_srt_time(t)
    {
        if (t ~ /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9],[0-9][0-9][0-9]$/)
            return 1

        if (t ~ /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/)
            return 1

        return 0
    }

    function srt_time_2_ms(t, _n, _t_arr, _s, _ms)
    {
        _n = split(t, _t_arr, /[:,]/)

        _s  = _t_arr[1] * 3600
        _s += _t_arr[2] * 60
        _s += _t_arr[3] * 1
        _ms = _s * 1000
        if (_n == 4)
            _ms += _t_arr[4]

        return _ms
    }

    function ms_2_srt_time(ms, _t, _h, _m, _s, _ms)
    {
        #test case
        #_t  = ((3 * 3600) + (15 * 60) + 23) * 1000 + 567

        _t  = ms
        _ms = _t % 1000
        _t  = int(_t / 1000)

        _h  = int(_t / 3600)
        _t  = _t % 3600

        _m  = int(_t / 60)
        _t  = _t % 60

        _s  = _t

        return sprintf("%02d:%02d:%02d,%03d", _h, _m, _s, _ms)
    }

    function copy_array(from, to, _i)
    {
        for (_i in from)
            to[_i] = from[_i]
    }

    function reset_array(arr, _i)
    {
        for (_i in arr)
            arr[_i] = 0
    }

    function set_curr_end_time_str(_min, _ms)
    {
        _min = curr["phrase_word_count"]/v_wpm    # we get a float here
        _ms  = (_min * 60) * 1000

        curr["begin_time_ms"]     = srt_time_2_ms(curr["begin_time_str"])
        curr["duration_ms"]       = int(_ms)
        curr["comp_end_time_ms"]  = curr["begin_time_ms"] + curr["duration_ms"]
        curr["comp_end_time_str"] = ms_2_srt_time(curr["comp_end_time_ms"])
    }

    function dump_segment(ctx)
    {
        print ctx["index"]
        print ctx["begin_time_str"] " --> " ctx["end_time_str"]

        for (_i = 0; _i < ctx["phrase_line_count"]; ++_i)
            print phrase_lines[_i]

        print ""
    }

    function dump_debug_header()
    {
        print "INDEX,"              \
              "TR_GOOD,"            \
              "NUM_PHRASE_LINES,"   \
              "NUM_PHRASE_WORDS,"   \
              "WPM,"                \
              "DURATION_MS,"        \
              "BEGIN_TIME,"         \
              "BEGIN_TIME_MS,"      \
              "COMP_END_TIME,"      \
              "COMP_END_TIME_MS,"   \
              "END_TIME,"           \
              "END_TIME_MS,"        \
              "TOLERANCE,"          \
              "END_TRUNCATED"       \
              > "/dev/stderr"
    }

    function dump_debug_info(ctx)
    {
        bts = ctx["begin_time_str"]
        sub(/,/,".",bts)

        cets = ctx["comp_end_time_str"]
        sub(/,/,".",cets)

        ets = ctx["end_time_str"]
        sub(/,/,".",ets)

        print ctx["index"] ","             \
              ctx["time_range_good"] ","   \
              ctx["phrase_line_count"] "," \
              ctx["phrase_word_count"] "," \
              v_wpm ","                    \
              ctx["duration_ms"] ","       \
              bts ","                      \
              ctx["begin_time_ms"] ","     \
              cets ","                     \
              ctx["comp_end_time_ms"] ","  \
              ets ","                      \
              ctx["end_time_ms"] ","       \
              v_tolerance_ms ","           \
              ctx["end_truncated"]         \
              > "/dev/stderr"
    }

    function infer_and_dump_prev_segment()
    {
        time_diff_ms = prev["comp_end_time_ms"] - curr["begin_time_ms"]

        if (time_diff_ms > v_tolerance_ms)
        {
            printf "at line %d : prev end time %s for segment %d " \
                   "exceeds curr begin time %s for segment %d " \
                   "by more than %d ms, try with higher wpm\n", \
                   line_num, \
                   prev["comp_end_time_str"], \
                   prev["index"], \
                   curr["begin_time_str"], \
                   curr["index"], \
                   v_tolerance_ms \
                   > "/dev/stderr"
            error = 1
            exit (1)
        }

        if (time_diff_ms > 0)
        {
            prev["end_time_str"]  = curr["begin_time_str"]
            prev["end_time_ms"]   = curr["begin_time_ms"]
            prev["end_truncated"] = 1
        }
        else
        {
            prev["end_time_str"] = prev["comp_end_time_str"]
            prev["end_time_ms"]  = prev["comp_end_time_ms"]
        }

        if (v_debug)
            dump_debug_info(prev)

        dump_segment(prev)
    }

    function infer_and_dump_curr_segment()
    {
        curr["end_time_str"] = curr["comp_end_time_str"]
        curr["end_time_ms"]  = curr["comp_end_time_ms"]

        if (v_debug)
            dump_debug_info(curr)

        dump_segment(curr)
    }

'

