---
layout: post
title: Git Loves the Environment
---

One of the things that people that come from the Subversion world tend
to find pretty cool about Git is that there is no `.svn` directory in
every subdirectory of your project, but instead just one `.git` directory
in the root of your project.  Actually, it's even better than that.
The `.git` directory does not even need to actually be within your project.
Git allows you to tell it where your `.git` directory is, and there are
a couple of ways to do that.

Let's say you have your project and want to move the `.git` directory 
somewhere else.  First let's see what happens when we move our `.git`
directory without telling Git.
  
	$ git log --oneline
	6e948ec my second commit
	fda8c93 my initial commit
	$ mv .git /opt/myproject.git
	$ git log
	fatal: Not a git repository (or any of the parent directories): .git

Well, since Git can't find a `.git` direcotry, it appears that you are
simply in a directory that is not controlled by Git.  However, it's
pretty easy to tell Git to look elsewhere by providing the `--git-dir`
option to any Git call:

	$ git --git-dir=/opt/myproject.git log --oneline
	6e948ec my second commit
	fda8c93 my initial commit

However, you probably don't want to do that for every Git call, as
that is a lot of typing.  You could create a shell alias, but you can
also export an environment variable called `GIT_DIR`.

	$ export GIT_DIR=/opt/myproject.git
	$ git log --oneline
	6e948ec my second commit
	fda8c93 my initial commit

There are a number of ways to customize Git functionality via specific 
environment variables.  You can also tell Git where your working directory
is with `GIT_WORK_TREE`, so you can run the Git commands from any
directory you are in, not just the current working directory. To see this,
first we'll change a file and then change directories and run `git status`.

	$ echo 'test' >> README 
	$ git status --short
	M README

OK, but now if we change working directories, we'll get weird output.

	$ cd /tmp
	$ git status --short
	 D README
	 ?? .ksda.1F5/
	 ?? aprKhGx02
	 ?? qlm.log
	 ?? qlmlog.txt
	 ?? smsi02122

Now Git is comparing your last commit to what is in your current working 
directory.  However, you can tell it where your real Git working directory
is without being in it, either with the `--work-tree` option or by exporting
the `GIT_WORK_TREE` variable:

	$ git --work-tree=/tmp/myproject status --short
	 M README
	$ export GIT_WORK_TREE=/tmp/myproject
	$ git status --short
	 M README

Now you're doing operations on a Git repository outside of your working
directory, which you're not even in.

The last interesting variable you can set is your staging area.  That
is normally in the `.git/index` file, but again, you can set it somewhere
else, so that you can have multiple staging areas that you can switch
between if you want.

	$ export GIT_INDEX_FILE=/tmp/index1
	$ git add README
	$ git status
	# On branch master
	# Changes to be committed:
	#   (use "git reset HEAD <file>..." to unstage)
	#
	# modified:   README
	#

Now we have the README file changed staged in the new index file.  If we
switch back to our original index, we can see that the file is no longer
staged:

	$ export GIT_INDEX_FILE=/opt/myproject.git/index
	$ git status
	# On branch master
	# Changed but not updated:
	#   (use "git add <file>..." to update what will be committed)
	#   (use "git checkout -- <file>..." to discard changes in working directory)
	#
	# modified:   README
	#
	no changes added to commit (use "git add" and/or "git commit -a")

This is not quite as useful in day to day work, but it is pretty cool for 
building arbitrary trees and whatnot.  We'll explore how to use that to 
do neat things in a future post when we talk more about some of the lower
level Git plumbing commands.
