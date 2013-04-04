---
layout: post
title: Smart HTTP Transport
---

When I was done writing Pro Git, the only transfer protocols that existed were
the `git://`, `ssh://` and basic `http://` transports.  I wrote about the basic
strengths and weaknesses of each in <a href="/book/ch4-1.html">Chapter 4</a>.
At the time, one of the big differences between Git and most other VCS's was
that HTTP was not a mainly used protocol - that's because it was read-only and
very inefficient.  Git would simply use the webserver to ask for individual
objects and packfiles that it needed.  It would even ask for big packfiles even
if it only needed one object from it.

As of the release of version 1.6.6 at the end of last year, however, Git can
now use the HTTP protocol just about as efficiently as the `git` or `ssh`
versions (thanks to the amazing work by Shawn Pearce, who also happened to have
been the technical editor of Pro Git).  Amusingly, it has been given very little
fanfare - the release notes for 1.6.6 state only this:

	* "git fetch" over http learned a new mode that is different from the
	  traditional "dumb commit walker".

Which is a huge understatement, given that I think this will become the
standard Git protocol in the very near future.  I believe this because it's
both efficient and can be run either secure and authenticated (https) or open
and unauthenticated (http).  It also has the huge advantage that most
firewalls have those ports (80 and 443) open already and normal users don't
have to deal with `ssh-keygen` and the like.  Once most clients have updated
to at least v1.6.6, `http` will have a big place in the Git world.

<h2>What is "Smart" HTTP?</h2>

Before version 1.6.6, Git clients, when you clone or fetch over HTTP would
basically just do a series of GETs to grab individual objects and packfiles on
the server from bare Git repositories, since it knows the layout of the repo.
This functionality is documented fairly completely in <a href="http://progit.org/book/ch9-6.html">Chapter 9</a>.
Conversations over this protocol used to look like this:

	$ git clone http://github.com/schacon/simplegit-progit.git
	Initialized empty Git repository in /private/tmp/simplegit-progit/.git/
	got ca82a6dff817ec66f44342007202690a93763949
	walk ca82a6dff817ec66f44342007202690a93763949
	got 085bb3bcb608e1e8451d4b2432f8ecbe6306e7e7
	Getting alternates list for http://github.com/schacon/simplegit-progit.git
	Getting pack list for http://github.com/schacon/simplegit-progit.git
	Getting index for pack 816a9b2334da9953e530f27bcac22082a9f5b835
	Getting pack 816a9b2334da9953e530f27bcac22082a9f5b835
	 which contains cfda3bf379e4f8dba8717dee55aab78aef7f4daf
	walk 085bb3bcb608e1e8451d4b2432f8ecbe6306e7e7
	walk a11bef06a3f659402fe7563abf99ad00de2209e6

It is a completly passive server, and if the client needs one object in a packfile
of thousands, the server cannot pull the single object out, the client is forced
to request the entire packfile.

<img src="/images/smarthttp1.png">

In contrast, the smarter protocols (`git` and `ssh`) would instead have a
conversation with the `git upload-pack` process on the server which would
determine the exact set of objects the client needs and build a custom packfile
with just those objects and stream it over.

The new clients will now send a request with an extra GET parameter that older
servers will simply ignore, but servers running the smart CGI will recognize
and switch modes to a multi-POST mode that is similar to the conversation that
happens over the `git` protocol.  Once this series of POSTs is complete, the
server knows what objects the client needs and can build a custom packfile and
stream it back.

<img src="/images/smarthttp2.png">

Furthermore, in the olden days if you wanted to push over http, you had to setup
a DAV-based server, which was rather difficult and also pretty inefficient compared
to the smarter protocols.  Now you can push over this CGI, which again is very
similar to the push mechanisms for the `git` and `ssh` protocols.  You simply
have to authenticate via an HTTP-based method, like basic auth or the like
(assuming you don't want your repository to be world-writable).

The rest of this article will explain setting up a server with the "smart"-http
protocol, so you can test out this cool new feature.  This feature is referred
to as "smart" HTTP vs "dumb" HTTP because it requires having the Git binary
installed on the server, where the previous incantation of HTTP transfer
required only a simple webserver.  It has a real conversation with the client,
rather than just dumbly pushing out data.

<h2>Setting up Smart HTTP</h2>

So, Smart-HTTP is basically just enabling the new CGI script that is provided
with Git called
<a href="http://www.kernel.org/pub/software/scm/git/docs/git-http-backend.html">`git-http-backend`</a>
on the server.  This CGI will read the path and
headers sent by the revamped `git fetch` and `git push` binaries who have
learned to communicate in a specific way with a smart server.  If the CGI sees
that the client is smart, it will communicate smartly with it, otherwise it will
simply fall back to the dumb behavior (so it is backward compatible for reads
with older clients).

To set it up, it's best to walk through the instructions on the
<a href="http://www.kernel.org/pub/software/scm/git/docs/git-http-backend.html">`git-http-backend`</a>
documentation page.  Basically, you have to install Git v1.6.6 or higher on
a server with an Apache 2.x webserver (it has to be Apache, currently - other
CGI servers don't work, last I checked).  Then you add something similar to this
to your http.conf file:

	SetEnv GIT_PROJECT_ROOT /var/www/git
	SetEnv GIT_HTTP_EXPORT_ALL
	ScriptAlias /git/ /usr/libexec/git-core/git-http-backend/

Then you'll want to make writes be authenticated somehow, possibly with an Auth
block like this:

	<LocationMatch "^/git/.*/git-receive-pack$">
	        AuthType Basic
	        AuthName "Git Access"
	        Require group committers
	        ...
	</LocationMatch>

That is all that is really required to get this running.  Now you have a smart
http-based Git server that can do anonymous reads and authenticated writes with
clients that have upgraded to 1.6.6 and above.
How awesome is that?  The <a href="http://www.kernel.org/pub/software/scm/git/docs/git-http-backend.html">documentation</a>
goes over more complex examples, like making it work with GitWeb and accelerating
the dumb fallback reads, if you're interested.

<h2>Rack-based Git Server</h2>

If you're not a fan of Apache or you're running some other web server, you may
want to take a look at an app that I wrote called <a href="http://github.com/schacon/grack">Grack</a>, which
is a <a href="http://rack.rubyforge.org/">Rack</a>-based application for Smart-HTTP Git.
<a href="http://rack.rubyforge.org/">Rack</a> is a generic webserver interface
for Ruby (similar to WSGI for Python) that has adapters for a ton of web servers.
It basically replaces `git http-backend` for non-Apache servers that can't run it.

This means that I can write the web handler independent of the web server and it
will work with any web server that has a Rack handler.  This currently means any FCGI server,
Mongrel (and EventedMongrel and SwiftipliedMongrel), WEBrick, SCGI, LiteSpeed,
Thin, Ebb, Phusion Passenger and Unicorn.  Even cooler, using
<a href="http://caldersphere.rubyforge.org/warbler/classes/Warbler.html">Warbler</a>
and JRuby, you can generate a WAR file that is deployable in any Java web
application server (Tomcat, Glassfish, Websphere, JBoss, etc).

So, if you don't use Apache and you are interested in a Smart-HTTP Git server,
you may want to check out Grack.  At <a href="http://github.com">GitHub</a>, this
is the adapter we're using to eventually implement Smart-HTTP support for all
the GitHub repositories. (It's currently a tad bit behind, but I'll be starting
up on it again soon as I get it into production at GitHub - send pull requests if you
find any issues)

Grack is about half as fast as the Apache version for simple ref-listing stuff,
but we're talking 10ths of a second.  For most clones and pushes, the data transfer
will be the main time-sink, so the load time of the app should be negligible.

<h2>In Conclusion</h2>

I think HTTP based Git will be a huge part of the future of Git, so if you're
running your own Git server, you should really check it out.  If you're not,
GitHub and I'm sure other hosts will soon be supporting it - upgrade your Git
client to 1.7ish soon so you can take advantage of it when it happens.
