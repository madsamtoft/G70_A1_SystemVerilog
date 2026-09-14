namespace eval messages {}

proc messages::write {report_dir} {
    file mkdir $report_dir

    write_messages \
        -force \
        -file [file join $report_dir warnings.log] \
        -severity "WARNING"

    write_messages \
        -force \
        -file [file join $report_dir critical_warnings.log] \
        -severity [list "CRITICAL WARNING"]

    write_messages \
        -force \
        -file [file join $report_dir errors.log] \
        -severity "ERROR"
}