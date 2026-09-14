namespace eval simulation {}

proc simulation::run {} {
    set project_name [cfg::require PROJECT]
    set build_dir    [file normalize [cfg::require BUILD_DIR]]
    set sim_top      [cfg::require SIM_TOP]
    set sim_time     [cfg::require SIM_TIME]

    if {![project::is_open]} {
        error "simulation::run requires an open Vivado project"
    }

    set sim_dir [file join $build_dir sim]
    file mkdir $sim_dir

    set_property top $sim_top [get_filesets sim_1]
    set_property TARGET_SIMULATOR XSim [current_project]
    update_compile_order -fileset sim_1

    puts "Launching simulation: $sim_top"
    launch_simulation -mode behavioral

    set vcd_file [file join $sim_dir "${project_name}.vcd"]

    open_vcd $vcd_file
    log_vcd -level 0 /*

    puts "Running simulation for $sim_time"
    run $sim_time

    close_vcd
    close_sim

    puts "Simulation complete"
    puts "VCD: $vcd_file"
}
