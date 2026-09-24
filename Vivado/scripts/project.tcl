namespace eval project {}

proc project::file_path {} {
    set project_name [cfg::require PROJECT]
    set project_dir  [file normalize [cfg::require PROJECT_DIR]]
    return [file join $project_dir "${project_name}.xpr"]
}

proc project::is_open {} {
    return [expr {[current_project -quiet] ne ""}]
}

proc project::create {} {
    set project_name [cfg::require PROJECT]
    set top          [cfg::require TOP]
    set sim_top      [cfg::require SIM_TOP]
    set part         [cfg::require PART]

    set rtl_dir      [file normalize [cfg::require RTL_DIR]]
    set tb_dir       [file normalize [cfg::require TB_DIR]]
    set xdc_dir      [file normalize [cfg::require XDC_DIR]]
    set project_dir  [file normalize [cfg::require PROJECT_DIR]]

    set hdl          [cfg::hdl_language]
    set hdl_exts     [cfg::hdl_extensions]
    set vhdl_std     [cfg::require VHDL_STD]

    puts "Creating project: $project_name"
    puts "Source language: $hdl ([join $hdl_exts {, }])"

    create_project \
        -force \
        $project_name \
        $project_dir \
        -part $part

    # --------------------------------------------------------
    # Design sources
    # --------------------------------------------------------

    set rtl_files [util::find_files $rtl_dir $hdl_exts]

    if {[llength $rtl_files] == 0} {
        error "No $hdl RTL files found in $rtl_dir (expected: [join $hdl_exts {, }])"
    }

    add_files \
        -fileset sources_1 \
        -norecurse \
        $rtl_files

    # --------------------------------------------------------
    # Simulation sources
    # --------------------------------------------------------

    set tb_files [util::find_files $tb_dir $hdl_exts]

    if {[llength $tb_files] > 0} {
        add_files \
            -fileset sim_1 \
            -norecurse \
            $tb_files
    }

    # --------------------------------------------------------
    # Constraints
    # --------------------------------------------------------

    set xdc_files [util::find_files $xdc_dir {.xdc}]

    if {[llength $xdc_files] > 0} {
        add_files \
            -fileset constrs_1 \
            -norecurse \
            $xdc_files
    }

    # --------------------------------------------------------
    # HDL file types
    # --------------------------------------------------------

    foreach fileset {sources_1 sim_1} {

        # SystemVerilog
        set sv_files [get_files \
            -quiet \
            -of_objects [get_filesets $fileset] \
            -filter {NAME =~ "*.sv"}]

        if {[llength $sv_files] > 0} {
            set_property FILE_TYPE SystemVerilog $sv_files
        }

        # VHDL 2008, if requested
        if {$vhdl_std eq "2008"} {
            set vhdl_files [get_files \
                -quiet \
                -of_objects [get_filesets $fileset] \
                -filter {FILE_TYPE == VHDL}]

            if {[llength $vhdl_files] > 0} {
                set_property FILE_TYPE {VHDL 2008} $vhdl_files
            }
        }
    }

    # --------------------------------------------------------
    # Tops and simulator
    # --------------------------------------------------------

    set_property top $top [get_filesets sources_1]

    if {[llength $tb_files] > 0} {
        set_property top $sim_top [get_filesets sim_1]
    }

    set_property TARGET_SIMULATOR XSim [current_project]

    update_compile_order -fileset sources_1

    if {[llength $tb_files] > 0} {
        update_compile_order -fileset sim_1
    }

    puts "Project created:"
    puts "  [project::file_path]"
}

proc project::open_existing {} {
    if {[project::is_open]} {
        return
    }

    set project_file [project::file_path]

    if {![file exists $project_file]} {
        error "Project does not exist: $project_file"
    }

    puts "Opening project: $project_file"
    open_project $project_file
}

proc project::close_if_open {} {
    if {[project::is_open]} {
        close_project
    }
}
