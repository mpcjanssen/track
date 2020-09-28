tcl::tm::path add [file join [file dirname [info script]] modules]


package require dustmote4track
package require router
package require track

package require service

namespace import track::*

set track::assets [file join [file dir [info script]] assets]
set router::debug true
set routes {
  /service/:id                service::handler
  /css/default.css            {track::asset default.css text/css}
  /css/highlight.css            {track::asset highlight.css text/css}
  /js/highlight.js            {track::asset highlight.js  text/javascript}
  /favicon.ico            {410}
  /error		      {!error oops}
  /doc                        {track::md ../README.md}
  /                           {track::md index.md}
  /console			              {!console show}
  /exit			                  {!exit}
  @rest                       track::debug_req
}
catch {
  package require Tk
  wm withdraw .
}

proc 410 {args} {
	return {status 410 body {} mode text headers {}}
}


# scgi::start 9999 [list router::route $routes] 
dustmote4track::start 9999 [list router::route $routes] 

# wapp4track::start 12345 track::debug_req
vwait forever
