namespace eval pins {}

proc pins::read_mapping {mapping_file} {
    array set port_for_pin {}

    if {![file exists $mapping_file]} {
        return [array get port_for_pin]
    }

    set mapping_fd [open $mapping_file "r"]

    while {[gets $mapping_fd line] >= 0} {
        set line [string trim $line]

        if {$line eq "" || [string match "#*" $line]} {
            continue
        }

        set separator [string first "=" $line]

        if {$separator < 1} {
            close $mapping_fd
            error "Invalid pin mapping '$line', expected PACKAGE_PIN=PORT_NAME"
        }

        set pin [string toupper [string trim \
            [string range $line 0 [expr {$separator - 1}]]]]
        set port [string trim \
            [string range $line [expr {$separator + 1}] end]]

        if {$pin eq "" || $port eq ""} {
            close $mapping_fd
            error "Invalid pin mapping '$line', expected PACKAGE_PIN=PORT_NAME"
        }

        if {[info exists port_for_pin($pin)]} {
            close $mapping_fd
            error "Pin $pin assigned more than once"
        }

        set port_for_pin($pin) $port
    }

    close $mapping_fd
    return [array get port_for_pin]
}

proc pins::generate {} {
    set xdc_dir [file normalize [cfg::require XDC_DIR]]

    set mapping_file [file join $::flow_root_dir pins.txt]
    set output_file  [file join $xdc_dir pins.xdc]

    if {![project::is_open]} {
        error "pins::generate requires an open Vivado project"
    }

    # Elaborate RTL only so Vivado exposes package-pin information for the
    # selected device. The project remains open after close_design.
    synth_design -rtl -name rtl_1

    array set port_for_pin [pins::read_mapping $mapping_file]

    set pins [get_package_pins -filter {
        IS_BONDED == 1 &&
        IS_GENERAL_PURPOSE == 1
    }]

    puts "Found [llength $pins] usable GPIO pins."

    foreach pin [array names port_for_pin] {
        if {[lsearch -exact $pins $pin] < 0} {
            close_design
            error "Mapped pin $pin is not a usable GPIO pin"
        }
    }

    array set bank_pins {}

    foreach pin $pins {
        set bank [get_property BANK $pin]
        lappend bank_pins($bank) $pin
    }

    file mkdir $xdc_dir
    set fd [open $output_file "w"]

    puts $fd "# ============================================================"
    puts $fd "# Auto-generated pin constraints"
    puts $fd "# Device: [get_property PART [current_project]]"
    puts $fd "#"
    puts $fd "# Pin mappings are read from:"
    puts $fd "#   pins.txt"
    puts $fd "#"
    puts $fd "# Clock constraints must be added separately."
    puts $fd "# ============================================================"

    foreach bank [lsort -integer [array names bank_pins]] {
        puts $fd ""
        puts $fd ""
        puts $fd "# ============================================================"
        puts $fd "# BANK $bank"
        puts $fd "# ============================================================"
        puts $fd ""

        foreach pin [lsort $bank_pins($bank)] {
            set func     [get_property PIN_FUNC $pin]
            set diff_pin [get_property DIFF_PAIR_PIN $pin]

            puts $fd "# Pin:      $pin"
            puts $fd "# Function: $func"

            if {$diff_pin ne ""} {
                puts $fd "# Diff pair: $diff_pin"
            }

            if {[info exists port_for_pin($pin)]} {
                set port $port_for_pin($pin)
                puts $fd "set_property PACKAGE_PIN $pin \[get_ports {$port}\]"
                puts $fd "set_property IOSTANDARD LVCMOS33 \[get_ports {$port}\]"
            } else {
                puts $fd "# set_property PACKAGE_PIN $pin \[get_ports {<PORT>}\]"
                puts $fd "# set_property IOSTANDARD LVCMOS33 \[get_ports {<PORT>}\]"
            }

            puts $fd ""
        }
    }

    close $fd
    close_design

    # If pins.xdc did not exist when project::create ran, add it now so a
    # following build stage in this same Vivado process uses it immediately.
    if {[llength [get_files -quiet $output_file]] == 0} {
        add_files \
            -fileset constrs_1 \
            -norecurse \
            $output_file
    }

    puts ""
    puts "Generated XDC:"
    puts "  $output_file"
    puts "Mapped pins: [array size port_for_pin]"
}
