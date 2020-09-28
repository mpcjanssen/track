package require track
namespace import track::*

namespace eval dustmote4track {
    variable _router
    proc listen {host port router} {
	variable _router
	set _router $router
	socket -server [namespace code answer] -myaddr $host $port
    }

proc answer {socketChannel host2 port2} {
    fileevent $socketChannel readable [list {*}[namespace code readIt] $socketChannel]
}

proc readIt {socketChannel} {
    variable _router
    fconfigure $socketChannel -blocking 0
    set gotLine [gets $socketChannel]
    if { [fblocked $socketChannel] } then {return}
    fileevent $socketChannel readable ""
    set shortName "/"
    regexp {/[^ ]*} $gotLine shortName
    set many [string length $shortName]
    set last [string index $shortName [expr {$many-1}] ]
    set start [clock milliseconds]

    set req [list headers {REQUEST_METHOD GET QUERY_STRING {}} body {} path $shortName cb [namespace code [list response $socketChannel]]]
    dict set req ms $start

    puts "Handling $shortName"
    response $socketChannel [clock milliseconds] [namespace inscope :: [list {*}$_router $req]]
}
proc response {socketChannel start res} {
    dict with res {
	if {$mode eq "cb"} {
	    # result will come later with a call back
	    return
	}
	fconfigure $socketChannel -translation crlf
	puts $socketChannel "HTTP/1.0 200 OK"		
    	puts $socketChannel ""
	switch -exact $mode {
	    text {
		puts -nonewline $socketChannel $body
	    }
	    list {
		foreach l $body {
		    puts -nonewline $socketChannel $l
		}
	    }
	    chan {
		fconfigure $socketChannel -translation binary
		fileevent $body readable {}
		set ret [fcopy $body $socketChannel]
		close $body
	    }
	}
	close $socketChannel
    }
}

proc start {port handlerprefix} {
    puts "Listening on port $port"
    listen localhost $port $handlerprefix

}
}


