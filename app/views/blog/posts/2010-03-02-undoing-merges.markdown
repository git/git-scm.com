---
layout: post
title: Undoing Merges
---

I would like to start writing more here about general Git tips, tricks and
upcoming features.  There has actually been a lot of cool stuff that has
happened since the book was first published, and a number of interesting
things that I didn't get around to covering in the book.  I figure if I start
blogging about the more interesting stuff, it should serve as a pretty handy
guide should I ever start writing a second edition.

For the first such post, I'm going to cover a topic that was asked about
at a training I did recently.  The question was about a workflow where long
running branches are merged occasionally, much like the <a href="http://progit.org/book/ch5-3.html#largemerging_workflows">Large Merging</a>
workflow that I describe in the book.  They asked how to unmerge a branch,
either permenantly or allowing you to merge it in later.

You can actually do this a number of ways.  Let's say you have history that
looks something like this:

<img src="/images/unmerge1.png">

You have a couple of topic branches that you have developed and then integrated
together by a series of merges.  Now you want to revert something back in the
history, say 'C10' in this case.

The first way to solve the problem could be to rewind 'master' back to C8 and
then merge the remaining two lines back in again.  This requires that anyone
you're collaborating with knows how to handle rewound heads, but if that's not
an issue, this is a perfectly viable solution.  This is basically how the 'pu'
branch is handled in the Git project itself.

	$ git checkout master
	$ git reset --hard [sha_of_C8]
	$ git merge jk/post-checkout
	$ git merge db/push-cleanup

Once you rewind and remerge, you'll instead have a history that looks more
like this:

<img src="/images/unmerge2.png">

Now you can go back and work on that newly unmerged line and merge it again
at a later point, or perhaps ignore it entirely.

<h2>Reverting a Merge</h2>

However, what if you didn't find this out until later, or perhaps you or one
of your collaborators have done work after this merge series? What if your
history looks more like this:

<img src="/images/unmerge3.png">

Now you either have to revert one of the merges, or go back, remerge and then
cherry-pick the remaining changes again (C9 and C10 in this case), which is
confusing and difficult, especially if there are a lot of commits after those
merges.

Well, it turns out that Git is actually pretty good at reverting an entire merge.
Although you've probably only used the `git revert` command to revert a single
commit (if you've used it at all), you can also use it to revert merge commits.

All you have to do is specify the merge commit you want to revert and the parent
line you want to keep.  Let's say that we want to revert the merge of the
`jk/post-checkout` line.  We can do so like this:

	$ git revert -m 1 [sha_of_C8]
	Finished one revert.
	[master 88edd6d] Revert "Merge branch 'jk/post-checkout'"
	 1 files changed, 0 insertions(+), 2 deletions(-)

That will introduce a new commit that undoes the changes introduced by merging
in the branch in the first place - sort of like a reverse cherry pick of all
of the commits that were unique to that branch.  Pretty cool.

<img src="/images/unmerge4.png">

However, we're not done.

<h2>Reverting the Revert</h2>

Let's say now that you want to re-merge that work again.  If you try to merge
it again, Git will see that the commits on that branch are in the history and
will assume that you are mistakenly trying to merge something you already have.

	$ git merge jk/post-checkout
	Already up-to-date.

Oops - it did nothing at all. Even more confusing is if you went back and committed on that branch
and then tried to merge it in, it would only introduce the changes _since_ you
originally merged.

<img src="/images/unmerge5.png">

Gah.  Now that's really a strange state and is likely to cause a bunch of
conflicts or confusing errors.  What you want to do instead is revert the revert
of the merge:

	$ git revert 88edd6d
	Finished one revert.
	[master 268e243] Revert "Revert "Merge branch 'jk/post-checkout'""
	 1 files changed, 2 insertions(+), 0 deletions(-)

<img src="/images/unmerge6.png">

Cool, so now we've basically reintroduced everything that was in the branch
that we had reverted out before.  Now if we have more work on that branch
in the meantime, we can just re-merge it.

	$ git merge jk/post-checkout
	Auto-merging test.txt
	Merge made by recursive.
	 test.txt |    1 +
	 1 files changed, 1 insertions(+), 0 deletions(-)

<img src="/images/unmerge7.png">

So, I hope that's helpful.  This can be particularly useful if you have a merge-heavy
development process.  In fact, if you work mostly in topic branches before
merging for intergration purposes, you may want to use the `git merge --no-ff`
option so that the first merge is not a fast forward and can be reverted out
in this manner.

Until next time.
