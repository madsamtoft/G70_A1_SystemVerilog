# Single Vivado entry point.
#
# Example:
#   vivado -mode batch -source scripts/flow.tcl -tclargs \
#       FLOW="project pins build sim" \
#       PROJECT=example ...


set script_dir [file dirname [file normalize [info script]]]
set ::flow_root_dir [file normalize [file join $script_dir ".."]]

# --------------------------------------------------------------------------
# Vivado Tcl Store support
# --------------------------------------------------------------------------

set tclapp_appinit_dir [file join \
    $env(HOME) \
    .Xilinx \
    Vivado \
    [version -short] \
    XilinxTclStore \
    support \
    appinit]

if {[file isdirectory $tclapp_appinit_dir]} {
    if {[lsearch -exact $::auto_path $tclapp_appinit_dir] == -1} {
        lappend ::auto_path $tclapp_appinit_dir
    }

    package require ::tclapp::support::appinit
}

# --------------------------------------------------------------------------
# Flow modules
# --------------------------------------------------------------------------

source [file join $script_dir common.tcl]
source [file join $script_dir messages.tcl]
source [file join $script_dir project.tcl]
source [file join $script_dir generate_xdc.tcl]
source [file join $script_dir build.tcl]
source [file join $script_dir simulate.tcl]

cfg::parse {*}$argv

set raw_flow [cfg::require FLOW]
set stages [regexp -all -inline {[^,[:space:]]+} $raw_flow]

if {[llength $stages] == 0} {
    error "FLOW must contain at least one stage"
}

set valid_stages {project pins build sim}

foreach stage $stages {
    if {$stage ni $valid_stages} {
        error "Unknown FLOW stage '$stage'. Valid stages: $valid_stages"
    }
}

# Creating a project halfway through a flow would invalidate state produced by
# previous stages, so require it to be the first stage when it is requested.
set project_index [lsearch -exact $stages project]
if {$project_index > 0} {
    error "The 'project' stage must be first in FLOW"
}

set build_dir  [file normalize [cfg::require BUILD_DIR]]
set report_dir [file join $build_dir reports]
file mkdir $build_dir

set exit_code 0

if {[catch {
    # A flow without 'project' operates on the existing .xpr. It is opened
    # once here and kept open for every requested stage.
    if {$project_index < 0} {
        project::open_existing
    }

    foreach stage $stages {
        util::banner "FLOW: [string toupper $stage]"

        switch -- $stage {
            project { project::create }
            pins    { pins::generate }
            build   { build::run }
            sim     { simulation::run }
        }
    }

    # One combined message dump for the whole Vivado session.
    messages::write $report_dir

} result options]} {
    set exit_code 1
    puts stderr ""
    puts stderr "FLOW FAILED:"
    puts stderr $result

    # Best effort: preserve Vivado warnings/errors even when a stage fails.
    catch {messages::write $report_dir}
    catch {close_sim}
    catch {close_design}
}

project::close_if_open

if {$exit_code == 0} {
    puts ""
    puts "FLOW COMPLETE: [join $stages { -> }]"
}

exit $exit_code
