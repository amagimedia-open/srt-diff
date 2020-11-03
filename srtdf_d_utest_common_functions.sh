function tap_utest_begins
{
    echo ""
    #echo "# $UTESTNUM $BARENAME begins"
}

function tap_utest_ends
{
    #echo "# $UTESTNUM $BARENAME ends"
    echo ""
}

function tap_utest_diag_msg
{
    local _message="$1"

    echo "# $_message"
}

function tap_utest_passed
{
    echo "ok $UTESTNUM $BARENAME"
}

function tap_utest_failed
{
    echo "not ok $UTESTNUM $BARENAME"
}

function is_output_ok
{
    local _utest_output_filepath="$1"

    local _gold_filepath=${BARENAME}.gold.txt
    local _failed_filepath=${BARENAME}.failed.txt

    if ! diff $_utest_output_filepath $_gold_filepath &>/dev/null
    then
        tap_utest_diag_msg "output differs from $_gold_filepath"
        tap_utest_diag_msg "storing failed output in $_failed_filepath"
        cp $_utest_output_filepath $_failed_filepath
        chmod +r $_failed_filepath
        return 1
    fi

    return 0
}

