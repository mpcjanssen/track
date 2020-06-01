# Tcl on Track

A work in progress library for making a small web framework. Heavily inspired by the Elixir Phoenix framework request pipelining and routing and Clojure Rack data structures.

The name is a pun on Rails and starts with a T so we have Tcl on Track.

# Design

   * Functional: most functions will transform a dicts containing the information about the request or produce a response.
   * Composable: it should be possible to combine request dict transformers in arbitrary order. This makes it possible to pick and choose parts of the "framework" and make it easy to extend. 
   * Prefix based: All defined callbacks are treated as prefixes.
   * Re-usable: The transformers should be usable with any dict of the right structure. For example, the router could be useful in other contexts than web servers and should be usable in that way.
   * Explicit: there should be no magic. The flow of application should be easy to follow. An example is the routing table specifying the exact proc that is called. And handlers needing to extract the request params instead of upvar or similar gymnastics.
   * Standard: basic Tcl structures and idioms should be used as much as possible. So for example the routes definition is a simple Tcl list which can be dynamically built and modified using standard Tcl.


# Components


## Server

Libraries of server connectors to convert the incoming request to a dict with the required parts correctly filled. For example socket should contain the client socket and path the query path. Once the request is handled. The server send the response back to the client.
A server can provide a cb element in the request dict which can be used to asynchronously handle the request. It's usally easiest to call the callback indirectly using `track::async_response $req $res`.

Available:

   * SCGI


### Contract

A server handles an incoming server connection and for every connection calls the handler prefix with request dict appended.

The request dict has at least the following elements:

- headers: the headers (if any) of the request
- path: the path of the request used by routers
- body: the body of the request
- cb: (optional) callback for asynchrounous handling
- ms: `[clock milliseconds]` at start of the request


After handling the request dict contains a response element with the following child elements:

- status: The status code to send to the client
- mode: either `text`, `list` or `chan`.
- body: The body to send to the client if mode = `text` or `list`. In case of list the body is iterated in a foreach. This allows creating responses step by step without having to concatenate it into a big string. The channel to fcopy if mode is `chan`.




## Router

The router library takes a request dict and takes the path element an a routes list. It will then determine which route matches and call the associated prefix command with the request dict as last parameter (or without if the prefix start with !)

While matching the route, parts which start with @ or : will match anything and the matched part will be stored in the req dict as params. The difference between @ and : is that @ will also match any following slashes.

Example:

```tcl
set routes {
    /rest/:id                    rest::handler
    /rest/:id/:subresource       rest::handler
    /flavor/a/:code          {flavor::handler a}
    /flavor/b/:code            {flavor::handler b}
    /css/default.css            {track::asset default.css text/css}
    /css/monokai.css            {track::asset monokai.css text/css}
    /                           {track::md index.md}
    /console                        {!console show}
    /exit                        {!exit}
    @rest                       track::debug_req
}
```

## Track

Library of transformer functions which take a dict and perform useful transformations and side effects. For example mirroring an additional http request to the client.

Also contains helper functions to extract parts of the request dict without assuming the structure. For example `[@p $req name]` to get the name parameter from the request.