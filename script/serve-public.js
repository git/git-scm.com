#!/usr/bin/env node

const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');

const basePath = path.join(__dirname, '..', 'public');

const mimeTypes = {
     "html": "text/html",
     "jpeg": "image/jpeg",
     "jpg": "image/jpeg",
     "png": "image/png",
     "ico": "image/x-icon",
     "js": "text/javascript",
     "css": "text/css",
     "json": "application/json",
     'pf_filter': 'application/gzip',
     'pf_fragment': 'application/gzip',
     'pf_index': 'application/gzip',
     'pf_meta': 'application/gzip',
     'pagefind': 'application/gzip',
};

const handler = (request, response) => {
    const pathname = decodeURIComponent(url.parse(request.url).pathname);
    let filename = path.join(basePath, pathname === "/" ? "index.html" : pathname);

    let stats = fs.statSync(filename, { throwIfNoEntry: false });
    if (!stats?.isFile() && !filename.match(/\.[A-Za-z0-9]{1,11}$/)) {
	    filename += ".html";
	    stats = fs.statSync(filename, { throwIfNoEntry: false });
    }
    try{
        if (!stats?.isFile()) throw new Error(`Not a file: ${filename}`);
        const fileStream = fs.createReadStream(filename);
        let mimeType = mimeTypes[path.extname(filename).split(".")[1]];
        if (!mimeType) throw new Error(`Could not get mime type for '${filename}'`)
        response.writeHead(200, {'Content-Type':mimeType});
        fileStream.pipe(response);
    } catch(e) {
        console.log(`Could not read ${filename}`);
        response.writeHead(404, {'Content-Type': 'text/plain'});
        response.write('404 Not Found\n');
        response.end();
        return;
    }
};

const server = http.createServer(handler);

server.on("listening", () => {
    console.log(`Now listening on: http://localhost:${server.address().port}/`);
});
server.listen(5000);
