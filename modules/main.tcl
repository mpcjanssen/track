tcl::tm::path add [file join [file dirname [info script]] modules]


package require scgi
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

scgi::start 9999 [list router::route $routes] 
# scgi::start 9999 scgi::debug_router
vwait forever
