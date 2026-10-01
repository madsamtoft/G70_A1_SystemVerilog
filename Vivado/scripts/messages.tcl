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

namespace eval reports {}

proc reports::write {report_dir} {
    file mkdir $report_dir

    report_utilization \
        -file [file join $report_dir utilization.rpt]

    report_timing_summary \
        -file [file join $report_dir timing_summary.rpt]

    report_clock_utilization \
        -file [file join $report_dir clock_utilization.rpt]

    report_route_status \
        -file [file join $report_dir route_status.rpt]

    report_design_analysis \
        -file [file join $report_dir design_analysis.rpt]
}