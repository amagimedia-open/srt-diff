function tap_plan
{
    local _num_cases=$1
    echo "1..$_num_cases"
}

function tap_utest_passed
{
    echo "ok $UTESTNUM $BARENAME"
}

function tap_utest_failed
{
    echo "not ok $UTESTNUM $BARENAME"
}

function tap_utest_diag_msg
{
    local _message="$1"

    echo "# $_message"
}

function tap_version
{
    echo "TAP version 13"
    tap_utest_diag_msg "see https://testanything.org/tap-specification.html"
    echo ""
}

function tap_utest_begins
{
    #echo "# $UTESTNUM $BARENAME begins"
    echo ""
}

function tap_utest_ends
{
    #echo "# $UTESTNUM $BARENAME ends"
    :
}

