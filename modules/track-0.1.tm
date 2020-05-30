namespace eval track {
  variable debug false
  variable assets .
  namespace export @p @c

  proc http_headers {req status headers} {
    set socket [@c $req]
    fconfigure $socket -translation crlf
    puts $socket "Status: $status OK"
    foreach {head val} $headers {
      puts $socket "$head: $val"
    }
    puts $socket ""
  }
  proc http_ok {req} {
    set socket [dict get $req socket]
    fconfigure $socket -translation crlf
    puts $socket "Status: 200 OK"
  }

  proc http_startbody {req} {
    set socket [dict get $req socket]
    fconfigure $socket -translation crlf
    puts $socket ""
  }

  proc @p {req name} {
    return [dict get $req params $name] 
  }

  proc @c {req} {
    return [dict get $req channel] 
  }

  proc debug_req {req} {
    package require html
    array set Headers [dict get $req headers]
    set body [dict get $req body]
    set sock [@c $req]

    puts $sock "Status: 200 OK"
    puts $sock "Content-Type: text/html"
    puts $sock ""
    puts $sock "<HTML>"
    puts $sock "<BODY>"
    puts $sock [::html::tableFromArray Headers]
    puts $sock "</BODY>"
    puts $sock "<H3>Body</H3>"
    puts $sock "<PRE>$body</PRE>"
    puts $sock "<H3>Req</H3>"
    puts $sock "<PRE>$req</PRE>"
    if {$Headers(REQUEST_METHOD) eq "GET"} {
      puts $sock {<FORM METHOD="post" ACTION="/scgi">}
      foreach pair [split $Headers(QUERY_STRING) &] {
        lassign [split $pair =] key val
        puts $sock "$key: [::html::textInput $key $val]<BR>"
      }
      puts $sock "<BR>"
      puts $sock {<INPUT TYPE="submit" VALUE="Try POST">}
    } else {
      puts $sock {<FORM METHOD="get" ACTION="/scgi">}
      foreach pair [split $body &] {
        lassign [split $pair =] key val
        puts $sock "$key: [::html::textInput $key $val]<BR>"
      }
      puts $sock "<BR>"
      puts $sock {<INPUT TYPE="submit" VALUE="Try GET">}
    }
    puts $sock "</FORM>"
    puts $sock "</HTML>"
    close $sock
  }

  proc httpmirror {req_socket socket token} {
    upvar 1 $token tok
    fileevent $socket readable {}
    fconfigure $req_socket -translation crlf
    puts $req_socket "Status: 200 OK"
    foreach {head val} $tok(meta) {
      puts $req_socket "$head: $val"
    }
    puts $req_socket ""
    fconfigure $req_socket -translation binary

    return [fcopy $socket $req_socket]

  }
  proc asset {file type req} {
    variable assets
    track::http_headers $req 200 [list Content-Type $type]
    set s [@c $req]
    set f [open [file join $assets $file] rb]
    fconfigure $s -translation binary
    fcopy $f $s
    close $f
    close $s

  }
  set header {<!DOCTYPE html>
              <html lang="en">
              <head>
              <meta charset="UTF-8">
              <!--[if IE]><meta http-equiv="X-UA-Compatible" content="IE=edge"><![endif]-->
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <meta name="generator" content="Asciidoctor 1.5.6.2">
              <link rel="stylesheet" type="text/css" href="/css/default.css">
              <link rel="stylesheet" type="text/css" href="/css/highlight.css">
              <script src="/js/highlight.js"></script>
              <script>hljs.initHighlightingOnLoad();</script>
              </head>
              <body class="article">
              <div id="header">
              </div>
              <div id="content">
  }
  set footer {</div>
              </body>
              </html>}

  proc md {file req} {
    package require cmark
    variable assets
    variable header
    variable footer
    track::http_headers $req 200 [list Content-Type text/html]
    set s [@c $req]
    set f [open [file join $assets $file] rb]
    puts $s $header[cmark::render [read $f] ]$footer
    close $f
    close $s

  }

}
