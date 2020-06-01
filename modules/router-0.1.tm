namespace eval router {

    # control debugging to stdout
    variable debug false

    # take the path element from the $req dict
    # match a against the routes list
    # :name will match until the next / and will [dict set $req params name]  
    # @name will match until the end and will [dict set $req params name]  
    # call the matching prefix command with the req dict appended
    # (if the first char of the prefix is !, the req is not appended)


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
		    set body [{*}[string range $prefixcmd 1 end]]
		    return [list status 200 body $body mode text headers {}]
		} 

	    }
	}
	error "No matching route for [dict get $req path]"
    }


    # helper for matching
    # creates a regexp from the route and matches it
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

