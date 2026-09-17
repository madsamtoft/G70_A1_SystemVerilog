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

    # Do not let launch_simulation automatically run 1000 ns.
    # Load the simulation snapshot and wait for Tcl commands.
    set_property xsim.simulate.runtime {} [get_filesets sim_1]

    update_compile_order -fileset sim_1

    puts "Launching simulation: $sim_top"
    launch_simulation -mode behavioral

    # ------------------------------------------------------------
    # VCD
    # ------------------------------------------------------------

    set vcd_file [file join $sim_dir "${project_name}.vcd"]

    puts "Opening VCD: $vcd_file"

    open_vcd $vcd_file
    log_vcd -level 0 /*

    # ------------------------------------------------------------
    # Run
    # ------------------------------------------------------------

    puts "Running simulation for $sim_time"

    # ::run is required because this procedure is simulation::run
    ::run $sim_time

    # ------------------------------------------------------------
    # Finish
    # ------------------------------------------------------------

    close_vcd
    close_sim

    puts "Simulation complete"
    puts "VCD: $vcd_file"
}