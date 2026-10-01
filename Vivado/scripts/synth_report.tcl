namespace eval synth_report {}

proc synth_report::run {} {
    set top        [cfg::require TOP]
    set part       [cfg::require PART]
    set rtl_dir    [file normalize [cfg::require RTL_DIR]]
    set build_dir  [file normalize [cfg::require BUILD_DIR]]
    set hdl        [cfg::hdl_language]
    set hdl_exts   [cfg::hdl_extensions]
    set vhdl_std   [cfg::require VHDL_STD]

    # RTL is stored in rtl/vhdl or rtl/sv
    set rtl_subdir [expr {$hdl eq "vhd" ? "vhdl" : "sv"}]
    set rtl_dir    [file join $rtl_dir $rtl_subdir]

    set report_dir [file join $build_dir reports]

    puts "============================================================"
    puts " Synthesis report"
    puts "============================================================"
    puts "Top:       $top"
    puts "Part:      $part"
    puts "RTL dir:   $rtl_dir"
    puts "Report dir:$report_dir"

    # --------------------------------------------------------
    # Find RTL
    # --------------------------------------------------------

    set rtl_files [util::find_files $rtl_dir $hdl_exts]

    if {[llength $rtl_files] == 0} {
        error "No $hdl RTL files found in $rtl_dir"
    }

    # --------------------------------------------------------
    # Read RTL
    # --------------------------------------------------------

    if {$hdl eq "vhd"} {
        if {$vhdl_std eq "2008"} {
            read_vhdl -vhdl2008 $rtl_files
        } else {
            read_vhdl $rtl_files
        }
    } elseif {$hdl eq "sv"} {
        read_verilog -sv $rtl_files
    } else {
        error "Unsupported HDL language: $hdl"
    }

    # --------------------------------------------------------
    # Synthesis
    # --------------------------------------------------------

    synth_design \
        -top $top \
        -part $part

    # --------------------------------------------------------
    # Reports
    # --------------------------------------------------------

    file mkdir $report_dir

    report_utilization \
        -file [file join $report_dir synthesis_utilization.rpt]

    puts "============================================================"
    puts " Synthesis complete"
    puts " Report:"
    puts " [file join $report_dir synthesis_utilization.rpt]"
    puts "============================================================"
}