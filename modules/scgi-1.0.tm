package require track
namespace import track::*

namespace eval scgi {
  variable _router
  proc listen {host port router} {
    variable _router
    set _router $router
    socket -server [namespace code connect] -myaddr $host $port
  }

  proc connect {sock ip port} {
    fconfigure $sock -blocking 0 -translation {binary crlf}
    fileevent $sock readable [namespace code [list read_length $sock {}]]
  }

  proc read_length {sock data} {
    append data [read $sock]
    if {[eof $sock]} {
      close $sock
      return
    }
    set colonIdx [string first : $data]
    if {$colonIdx == -1} {
      # we don't have the headers length yet
      fileevent $sock readable [namespace code [list read_length $sock $data]]
      return
    } else {
      set length [string range $data 0 $colonIdx-1]
      set data [string range $data $colonIdx+1 end]
      read_headers $sock $length $data
    }
  }

  proc read_headers {sock length data} {
    append data [read $sock]

    if {[string length $data] < $length+1} {
      # we don't have the complete headers yet, wait for more
      fileevent $sock readable [namespace code [list read_headers $sock $length $data]]
      return
    } else {
      set headers [string range $data 0 $length-1]
      set headers [lrange [split $headers \0] 0 end-1]
      set body [string range $data $length+1 end]
      set content_length [dict get $headers CONTENT_LENGTH]
      read_body $sock $headers $content_length $body
    }
  }

  proc read_body {sock headers content_length body} {
    variable _router
    append body [read $sock]

    if {[string length $body] < $content_length} {
      # we don't have the complete body yet, wait for more
      fileevent $sock readable [namespace code [list read_body $sock $headers $content_length $body]]
      return
    } else {
	response $sock [namespace inscope :: [list {*}$_router [list headers $headers body $body path [dict get $headers SCRIPT_NAME] cb [namespace code [list response $sock]]]]]
    }
  }

    proc response {sock res} {
	set ret {}
	if {$res eq {}} {
	    # async handling
	    # result is handled by callback
	    return
	}
	# if {[llength $res] %2 != 0} {puts $res ; error oops}
	dict with res {
	    fconfigure $sock -translation crlf
	    puts $sock "Status: $status OK"
	    foreach {head val} $headers {
		puts $sock "$head: $val"
	    }
	    puts $sock ""
	    switch -exact $mode {
		list {
		    foreach l $body {
			puts -nonewline $sock $l
		    }
		}
		chan {
		    fconfigure $sock -translation binary
		    fileevent $body readable {}
		    set ret [fcopy $body $sock]
		    close $body
		}
		
	    }
	}
	
	close $sock
        puts [chan names]
	return $ret
    }

  proc start {port handlerprefix} {
    puts "Listening on port $port"
    scgi::listen localhost 9999 $handlerprefix

  }
}


