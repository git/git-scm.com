---
layout: post
title: The Gory Details
---
First of all, thanks to everyone for spreading the word about this book and this site - I got _way_ more attention on the first day live than I expected I might.  More than 10,000 individuals visited the site in the first 24 hours of it being online for over 38k pageviews.  We got on Hacker News, Reddit and Delicious Popular aggregators, not to mention the Twitterverse.

In the comments of the initial post here, a user asked me about the "gory details" of writing this book. Specifically about "what tools you used to create the book and its figures".  So here it is.

Somewhere else I read that someone liked that I used Markdown for writing the book, as you can download the Markdown source for the book <a href="http://github.com/progit/progit">at GitHub</a>.  Well, the entire writing process was unfortunately not done in Markdown.  At Apress most of the editing and review process is still MS Word centric.  Since I threw hissy fits at Word for the first few chapters the very nice people at Apress allowed me to write the remainder of the book in Markdown initially and the technical reviews were done via a Git repository on GitHub using the Markdown source.

So, for most of the book, the process was : I would write the first draft of each chapter in Markdown, two reviewers would add comments inline.  Then, I would fix whatever they commented on then move the text into Word to submit it to the copy editor.  The copy editor would review the Word document and let the technical editor have another pass, then I would fix up anything they commented on.  Finally I get the chapter back in PDF form and I would do a final pass.  Then I took that text and put it back in Markdown to generate HTML from for the website.

Fun, huh?

For the diagrams, I always use OmniGraffle.  I personally think it's one of the most amazing pieces of software ever created - I love it.  I think normally an Apress designer would take whatever the author sketched and redo them, but in this case we actually just used the diagrams that I made.  I just added the .graffle file to the <a href="http://github.com/progit/progit">GitHub repo</a> if you're interested in it.