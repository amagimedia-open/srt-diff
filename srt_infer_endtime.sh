#!/bin/bash

set -u
#set -x

#----[temp files and termination]--------------------------------------------

TERMINATED=0

function fnxOnEnd
{
    ((TERMINATED==0)) && { rm -f $TMP1 $TMP2 $DEF_RANGE_SPEC_FILE_PATH; }
    TERMINATED=1
}

TMP1=`mktemp`
TMP2=`mktemp`
DEF_RANGE_SPEC_FILE_PATH=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[globals]------------------------------------------------------------------------

DIRNAME=$(readlink -e $(dirname $0))
MODNAME=$(basename $0)

G_MAPPED_ROOT_PATH=/data

cat <<EOD >$DEF_RANGE_SPEC_FILE_PATH

BEGIN_I,END_E,NAME
0,25,0000-0025-ms
25,50,0025-0050-ms
50,100,0050-0100-ms
100,200,0100-0200-ms
200,500,0200-0500-ms
500,1000,0500-1000-ms
1000,2000,1000-2000-ms
2000,*,2000-****-ms
EOD

#----[sources]---------------------------------------------------------------

source $DIRNAME/common_bash_functions.sh

#----[options]---------------------------------------------------------------

OPT_WORDS_PER_MIN=150
OPT_DEBUG=0

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

    which does not have an end time !

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

    It is expected that the input srt file is presented via stdin.
    The modified srt is presented via stdout.

OPTIONS

    -w words_per_minute
       This is optional. default is $OPT_WORDS_PER_MIN.

    -d
       Debug output on stderr.
       This is optional.

    -h
       Displays this help and quits.
       This is optional.

EOD
}

#----------------------------------------------------------------------------
# MAIN
#----------------------------------------------------------------------------

#+---------------------+
#| argument processing |
#+---------------------+

TEMP=`getopt -o "w:dh" -n "$0" -- "$@"`
eval set -- "$TEMP"

while true 
do
	case "$1" in
        -w) OPT_WORDS_PER_MIN=$2; shift 2;;
        -d) OPT_DEBUG=1; shift 1;;
        -h) usage; exit 0;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

#+-------------------------+
#| generate histogram data |
#+-------------------------+

gawk -v v_wpm=$OPT_WORDS_PER_MIN \
     -v v_debug=$OPT_DEBUG \
'
    BEGIN \
    {
        EOS_SEEN   = 1          # EOS => END OF SEGMENT (index + time range + phrase(s))
        INDEX_SEEN = 2
        TIME_RANGE_SEEN = 3

        state = EOS_SEEN
        error = 0
        line_num = 0

        if (v_debug)
            dump_debug_header()
    }

    {
        ++line_num

        if (state == EOS_SEEN)
        {
            if (is_empty_line())
                next

            init_segment()

            if (! is_srt_index())
            {
                printf "at line %d : expecting index", line_num > "/dev/stderr"
                error = 1
                exit (1)
            }

            curr_index = $0
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

            if (is_srt_time($2))
                curr_time_range_good = 1

            curr_begin_time_str = $1
            curr_end_time_str = $2
            state = TIME_RANGE_SEEN
            next
        }

        if (state == TIME_RANGE_SEEN)
        {
            if (! is_empty_line())
            {
                curr_phrase_lines[curr_phrase_line_count] = $0
                ++curr_phrase_line_count

                n_words = split($0, t_arr, /[ \t][ \t]*/)
                curr_phrase_word_count += n_words
                next
            }

            # we have seen a blank line here and thus
            # we have arrived at the end of a segment

            if (! curr_time_range_good)
                set_end_time_str()

            if (v_debug)
                dump_debug_info()

            dump_segment()

            state = EOS_SEEN
            next
        }
    }

    END \
    {
        if (error)
            exit(1)
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
        _t  = ms
        _ms = _t % 1000
        _t  = _t / 1000

        _h  = _t / 3600
        _t  = _t % 3600

        _m  = _t / 60
        _t  = _t % 60

        _s  = _t

        return _h ":" _m ":" _s "," _ms
    }

    function set_end_time_str(_begin_ms, _min, _end_ms)
    {
        _begin_ms = srt_time_2_ms(curr_begin_time_str)
        _min      = curr_phrase_word_count/v_wpm
        _end_ms   = _begin_ms + (_min * 60) * 1000
        _end_ms   = int(_end_ms)

        curr_end_time_str = ms_2_srt_time(_end_ms)
    }

    function init_segment()
    {
        curr_index = -1
        curr_time_range_good = 0
        curr_begin_time_str = ""
        curr_end_time_str = ""
        curr_phrase_line_count = 0
        curr_phrase_word_count = 0
        delete curr_phrase_lines
    }

    function dump_segment(_i)
    {
        print curr_index
        print curr_begin_time_str " --> " curr_end_time_str

        for (_i = 0; _i < curr_phrase_line_count; ++i)
            print curr_phrase_lines[_i]

        print ""
    }

    function dump_debug_header()
    {
        print "INDEX,"              \
              "TR_GOOD,"            \
              "NUM_PHRASE_LINES,"   \
              "NUM_PHRASE_WORDS,"   \
              "WPM,"                \
              "BEGIN_TIME,"         \
              "END_TIME"            \
              > "/dev/stderr"
    }

    function dump_debug_info()
    {
        print curr_index ","             \
              curr_time_range_good ","   \
              curr_phrase_line_count "," \
              phrase_word_count ","      \
              v_wpm ","                  \
              curr_begin_time_str ","    \
              curr_end_time_str          \
              > "/dev/stderr"
    }


'
