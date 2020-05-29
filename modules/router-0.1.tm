namespace eval router {
  variable debug false


  proc route {routes req} {
    variable debug
    # 
    # inject params in the request dict and call the command prefix as
    set path [dict get $req path]
    foreach {route prefixcmd} $routes {
      set vars [lassign [Match $route $path] match]
      if {$match} {
        if {$debug} {
          puts "Matched $path with $route"
        }
        foreach {name val} $vars {
          dict lappend req params $name $val
        }
        if {[string index $prefixcmd 0] ne "!"} {
          return [{*}$prefixcmd $req]
        } else {
          return [{*}[string range $prefixcmd 1 end]]
        } 

      }
    }
    error "No matching route for [dict get $req path]"
  }



  proc Match {route path} {
    set parts [split $route /]
    set vars {}
    set regexp {}
    foreach part $parts {
      switch -glob $part {
        :* { 
          lappend vars [string range $part 1 end]
          lappend regexp {([^/]+)}
        }
        @* {
          lappend vars [string range $part 1 end]
          lappend regexp {(.+)}
        }
        * {
          lappend regexp $part
        }

      }
    }
    set result {}
    if {[regexp ^[join $regexp /]\$ $path -> {*}$vars]} {
      lappend result 1
      foreach var $vars {
        lappend result $var [set $var]
      }
    } else {
      lappend result 0
    }
    return $result
  }
}

