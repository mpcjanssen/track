namespace eval track {
  variable debug false
  variable assets .
  namespace export @p @cb
  


  proc @p {req name} {
    return [dict get $req params $name] 
  }

  proc @cb {req} {
    return [dict get $req cb] 
  }


  proc debug_req {req} {
    package require html
    array set Headers [dict get $req headers]
    set body [dict get $req body]
    set result ""

    lappend result "<HTML>"
    lappend result "<BODY>"
    lappend result [::html::tableFromArray Headers]
    lappend result "</BODY>"
    lappend result "<H3>Body</H3>"
    lappend result "<PRE>$body</PRE>"
    lappend result "<H3>Req</H3>"
    lappend result "<PRE>$req</PRE>"
    if {$Headers(REQUEST_METHOD) eq "GET"} {
      lappend result {<FORM METHOD="post" ACTION="/scgi">}
      foreach pair [split $Headers(QUERY_STRING) &] {
        lassign [split $pair =] key val
        lappend result "$key: [::html::textInput $key $val]<BR>"
      }
      lappend result "<BR>"
      lappend result {<INPUT TYPE="submit" VALUE="Try POST">}
    } else {
      lappend result {<FORM METHOD="get" ACTION="/scgi">}
      foreach pair [split $body &] {
        lassign [split $pair =] key val
        lappend result "$key: [::html::textInput $key $val]<BR>"
      }
      lappend result "<BR>"
      lappend result {<INPUT TYPE="submit" VALUE="Try GET">}
    }
    lappend result "</FORM>"
    lappend result "</HTML>"
    return [list status 200 headers {Content-Type text/html} mode list body $result]
  }

  proc async_response {req res} {
    set cb [@cb $req]
    puts "Handling with cb $cb"
    set cb_cmd [lindex $cb end]
    lappend cb_cmd $res
    lset cb end $cb_cmd 
    return [{*}$cb]
  }
  
  proc httpmirror {req socket token} {
    upvar 1 $token tok
    fileevent $socket readable {}
    return [async_response $req [list status 200 mode chan body $socket headers $tok(meta)]]
    
  }
  
  proc asset {file type req} {
    variable assets
    set headers [list Content-Type $type]
    set status 200
    set f [open [file join $assets $file] rb]
    return [list status 200 headers $headers mode chan body $f] 
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
    set result [list status 200 headers {Content-Type text/html}]
    set f [open [file join $assets $file] rb]
    dict lappend result body $header
    dict lappend result body [cmark::render [read $f] ]
    dict lappend result body $footer
    dict set result mode list
    close $f
    return $result

  }

}
