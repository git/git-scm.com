module Gitscm
  CATEGORIES = [
    ['Setup and Config',
      ['git-config', 'git-help']
    ],['Getting and Creating Projects',
      ['git-init', 'git-clone']
    ],['Basic Snapshotting',
      ['git-add', 'git-status', 'git-diff', 'git-commit', 'git-reset', 'git-rm', 'git-mv']
    ],['Branching and Merging',
      ['git-branch', 'git-checkout', 'git-merge', 
       'git-mergetool', 'git-log', 'git-stash', 'git-tag']
    ],['Inspection and Comparison',
      ['git-show', 'git-log', 'git-diff', 'git-describe']
    ],['Patching',
      ['git-am', 'git-apply', 'git-cherry-pick', 'git-rebase']
    ],['Debugging',
      ['git-bisect', 'git-blame']
    ],['Email Workflow',
      ['git-am', 'git-apply', 'git-format-patch', 'git-send-email', 'git-request-pull']
    ],['External Systems',
      ['git-svn', 'git-fast-import']
    ],['Administration',
      ['git-clean', 'git-gc', 'git-fsck', 'git-reflog', 'git-filter-branch', 'git-instaweb', 'git-archive', 'git-bundle']
    ],['Server Admin',
      ['git-daemon', 'git-update-server-info']
    ],['Plumbing Commands',
      ['git-cat-file', 'git-commit-tree', 'git-count-objects', 'git-diff-index',
       'git-diff-tree', 'git-hash-object', 'git-merge-base', 'git-read-tree',
       'git-rev-list', '']
    ]
  ]
end
