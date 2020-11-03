function is_utest_output_ok
{
    local _utest_output_filepath="$1"

    local _gold_filepath=${BARENAME}.gold.txt
    local _failed_filepath=${BARENAME}.failed.txt

    if [[ ! -f $_utest_output_filepath ]]
    then
        tap_utest_diag_msg "$_utest_output_filepath not found"
        return 1
    fi

    if [[ ! -f $_gold_filepath ]]
    then
        tap_utest_diag_msg "$_gold_filepath not found"
        tap_utest_diag_msg "storing failed output in $_failed_filepath"
        cp $_utest_output_filepath $_failed_filepath
        chmod +r $_failed_filepath
        return 1
    fi

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

