namespace eval build {}

proc build::run {} {
    set project_name [cfg::require PROJECT]
    set top          [cfg::require TOP]
    set part         [cfg::require PART]
    set build_dir    [file normalize [cfg::require BUILD_DIR]]
    set jobs         [cfg::require JOBS]

    set phys_opt    [cfg::bool PHYS_OPT 0]
    set fail_timing [cfg::bool FAIL_TIMING 0]

    if {![project::is_open]} {
        error "build::run requires an open Vivado project"
    }

    file mkdir $build_dir

    set_param general.maxThreads $jobs

    set_property top $top [get_filesets sources_1]
    update_compile_order -fileset sources_1

    util::run_checked SYNTHESIS {
        synth_design \
            -top $top \
            -part $part
    }

    write_checkpoint \
        -force \
        [file join $build_dir post_synth.dcp]

    util::run_checked OPTIMIZATION {
        opt_design
    }

    util::run_checked PLACEMENT {
        place_design
    }

    write_checkpoint \
        -force \
        [file join $build_dir post_place.dcp]

    if {$phys_opt} {
        util::run_checked {PHYSICAL OPTIMIZATION} {
            phys_opt_design
        }
    }

    util::run_checked ROUTING {
        route_design
    }

    write_checkpoint \
        -force \
        [file join $build_dir post_route.dcp]

    set failing_paths [get_timing_paths \
        -quiet \
        -max_paths 1 \
        -slack_lesser_than 0]

    if {[llength $failing_paths] > 0} {
        set worst_slack [get_property SLACK [lindex $failing_paths 0]]
        puts "WARNING: Timing failed: ${worst_slack} ns"

        if {$fail_timing} {
            error "Timing constraints were not met."
        }
    }

    set bitstream [file join $build_dir "${project_name}.bit"]

    util::run_checked BITSTREAM {
        write_bitstream \
            -force \
            $bitstream
    }

    # Release the synthesized/implemented design but keep the project open,
    # allowing another stage (for example simulation) to run next.
    close_design

    puts ""
    puts "BUILD COMPLETE"
    puts "Bitstream: $bitstream"
}
