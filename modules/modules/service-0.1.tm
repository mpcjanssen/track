package require track
package require tls
package require http

namespace import track::*

namespace eval service {
 
    ::http::register https 443 [list ::tls::socket]


    proc handler {req} {
	set socket [dict get $req socket]

	set id [@p $req id]
	puts $id
    set subresource {}
    catch {
        set subresource [@p $req subresource ]
    }
	set req_socket [@s $req]
	set url https://www.google.com/search?[http::formatQuery q $id]
	http::geturl $url -handler [list track::httpmirror $req_socket]
	close $req_socket
    }
}
