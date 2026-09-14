namespace eval cfg {
    variable values
    array set values {}
}

proc cfg::parse {args} {
    variable values
    array unset values
    array set values {}

    foreach arg $args {
        set separator [string first "=" $arg]

        if {$separator < 1} {
            error "Invalid argument '$arg', expected KEY=VALUE"
        }

        set key   [string range $arg 0 [expr {$separator - 1}]]
        set value [string range $arg [expr {$separator + 1}] end]

        set values($key) $value
    }
}

proc cfg::require {name} {
    variable values

    if {![info exists values($name)]} {
        error "Missing required configuration variable: $name"
    }

    return $values($name)
}

proc cfg::get {name default} {
    variable values

    if {[info exists values($name)]} {
        return $values($name)
    }

    return $default
}

proc cfg::bool {name {default 0}} {
    set value [string tolower [cfg::get $name $default]]

    switch -- $value {
        1 - true - yes - on  { return 1 }
        0 - false - no - off { return 0 }
        default {
            error "Configuration variable $name must be boolean, got '$value'"
        }
    }
}

namespace eval util {}

proc util::find_files {directory extensions} {
    set result {}

    if {![file isdirectory $directory]} {
        return $result
    }

    foreach item [glob -nocomplain -directory $directory *] {
        if {[file isdirectory $item]} {
            set result [concat $result [util::find_files $item $extensions]]
            continue
        }

        set extension [string tolower [file extension $item]]

        if {$extension in $extensions} {
            lappend result $item
        }
    }

    return [lsort $result]
}

proc util::banner {name} {
    puts ""
    puts "============================================================"
    puts $name
    puts "============================================================"
}

proc util::run_checked {name script} {
    util::banner $name

    if {[catch {uplevel 1 $script} result options]} {
        puts stderr "ERROR during $name:"
        puts stderr $result
        return -options $options $result
    }

    return $result
}
