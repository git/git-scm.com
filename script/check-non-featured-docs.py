#!/usr/bin/env python3

import subprocess
import re
import argparse

# Parse input
parser = argparse.ArgumentParser( 
    description="Compare the commands featured on the reference page of the site to the complete list of Git commands.",
    epilog='Note: works only for GIT_VERSION >= v2.18.0',
    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-g", "--git-version", default='HEAD', help="git.git revision")
parser.add_argument("-s", "--site-version", default='HEAD', help="Site revision")
parser.add_argument("-r", "--git-repo", default='../git', help="git.git checkout")
args = parser.parse_args()

site_version = args.site_version
git_repo = args.git_repo
git_version = args.git_version

# Dict of ignored commands per categories
# See https://git-scm.com/docs/git#_git_commands
ignored_commands = {
# Main Porcelain Commands
'mainporcelain': {
'name': 'Main Porcelain Commands',
'commands': {
'git-citool',
'git-gui',
'gitk',
},},
# Ancillary Commands / Manipulator
'ancillarymanipulators': {
'name': 'Ancillary Commands / Manipulator',
'commands': {
'git-fast-export',
'git-pack-refs',
'git-prune',
'git-repack',
'git-replace',
},}, 
# Ancillary Commands / Interrogators
'ancillaryinterrogators': {
'name': 'Ancillary Commands / Interrogators',
'commands': {
'git-annotate',
'git-merge-tree', 
'git-rerere', 
'git-show-branch', 
'git-verify-commit', 
'git-verify-tag' ,
'git-whatchanged', 
'gitweb',
},},
# Interacting with Others
'foreignscminterface': {
'name': 'Interacting with Others',
'commands': {
'git-archimport', 
'git-cvsexportcommit', 
'git-cvsimport', 
'git-cvsserver', 
'git-p4', 
'git-quiltimport',
},},
# Low-level Commands / Manipulators
'plumbingmanipulators': {
'name': 'Low-level Commands / Manipulators',
'commands': {
'git-commit-graph',
'git-index-pack',
'git-merge-file',
'git-merge-index',
'git-mktag',
'git-mktree',
'git-multi-pack-index',
'git-pack-objects',
'git-prune-packed',
'git-unpack-objects',
},},
# Low-level Commands / Interrogators
'plumbinginterrogators': {
'name': 'Low-level Commands / Interrogators',
'commands': {
'git-cherry',
'git-diff-files',
'git-diff-tree',
'git-get-tar-commit-id',
'git-ls-remote',
'git-name-rev',
'git-pack-redundant',
'git-show-index',
'git-unpack-file',
'git-var',
},},
# Low-level Commands / Synching Repositories
'synchingrepositories': {
'name': 'Low-level Commands / Synching Repositories',
'commands': {
'git-fetch-pack',
'git-http-backend',
'git-send-pack',
},},
# Low-level Commands / Synching Helpers
'synchelpers': {
'name': 'Low-level Commands / Synching Helpers',
'commands': {
'git-http-fetch',
'git-http-push',
'git-parse-remote',
'git-receive-pack',
'git-shell',
'git-upload-archive',
'git-upload-pack',
},},
# Low-level Commands / Internal Helpers
'purehelpers': {
'name': 'Low-level Commands / Internal Helpers',
'commands': {
'git-check-attr',
'git-check-mailmap',
'git-check-ref-format',
'git-column',
'git-credential',
'git-credential-cache',
'git-credential-store',
'git-fmt-merge-msg',
'git-interpret-trailers',
'git-mailinfo',
'git-mailsplit',
'git-merge-one-file',
'git-patch-id',
'git-sh-i18n',
'git-sh-setup',
'git-stripspace',
},},
# Guides
'guide': {
'name': 'Guides',
'commands': {
'gitcore-tutorial',
'gitcvs-migration',
'gitdiffcore',
'gitnamespaces',
'gitrepository-layout',
'gittutorial-2',
},},
}

git_command_regex = 'git[0-9a-z-]+'
guides_pathspec = 'app/views/shared/ref/_guides.html.erb'
no_guides_pathspec = ':^' + guides_pathspec
commands_and_guides_pathspec = 'app/views/shared/ref/'
git_grep = 'grep -h --only-matching --recursive --no-line-number --no-column --extended-regexp'
git = ['git']

featured_commands = set(subprocess.check_output(git + git_grep.split() + [git_command_regex, site_version, commands_and_guides_pathspec, no_guides_pathspec], text=True).strip().split('\n'))
featured_guides   = set(subprocess.check_output(git + git_grep.split() + [git_command_regex, site_version, guides_pathspec], text=True).strip().split('\n'))

command_list_revision = git_version + ':' +  'command-list.txt'
command_list_lines = subprocess.check_output(git +  ['-C', git_repo, 'show', command_list_revision ], text=True).strip().split('\n')

print("Non-featured commands and guides:\n")

for category, ignored in ignored_commands.items():
    command_list_regex = re.compile('(' + git_command_regex + ')[ ]+' + category)
    all_commands = set([match.group(1) for match in (command_list_regex.match(line) for line in command_list_lines) if match])
    if category == 'guide':
        featured = featured_guides
    else:
        featured = featured_commands
    interesting = all_commands - ignored['commands']
    missing = interesting - featured
    num_missing = len(missing)
    if num_missing != 0:
        print(ignored['name'] + ' (' + str(num_missing) + '/' + str(len(all_commands)) + ', ' + str(len(ignored['commands']))  + ' ignored)')
        for command in missing:
            print(command)
        print('')

