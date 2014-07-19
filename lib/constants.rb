# ApplicationHelper
TAGLINES = %w{
    fast-version-control
    everything-is-local
    distributed-even-if-your-workflow-isnt
    local-branching-on-the-cheap
    distributed-is-the-new-centralized
}

# DocsController#commands
CMD_GROUPS = [
  ['Setup and Config', [ 'config', 'help' ]],
  ['Getting and Creating Projects', [ 'init', 'clone']],
  ['Basic Snapshotting', [ 'add', 'status', 'diff', 'commit', 'reset', 'rm', 'mv']],
  ['Branching and Merging', [ 'branch', 'checkout', 'merge', 'mergetool', 'log', 'stash', 'tag' ]],
  ['Sharing and Updating Projects', [ 'fetch', 'pull', 'push', 'remote', 'submodule' ]],
  ['Inspection and Comparison', [ 'show', 'log', 'diff', 'shortlog', 'describe' ]],
  ['Patching', ['am', 'apply', 'cherry-pick', 'rebase']],
  ['Debugging', [ 'bisect', 'blame' ]],
  ['Email', ['am', 'apply', 'format-patch', 'send-email', 'request-pull']],
  ['External Systems', ['svn', 'fast-import']],
  ['Administration', [ 'clean', 'gc', 'fsck', 'reflog', 'filter-branch', 'instaweb', 'archive' ]],
  ['Server Admin', [ 'daemon', 'update-server-info' ]],
]

#DocsControllers#watch
VIDEOS = [
  [1, "41027679", "Git Basics", "What is Version Control?", "what-is-version-control", "05:59"],
  [2, "41381741", "Git Basics", "What is Git?", "what-is-git", "08:15"],
  [3, "41493906", "Git Basics", "Get Going with Git", "get-going", "04:26"],
  [4, "41516942", "Git Basics", "Quick Wins with Git", "quick-wins", "05:06"],
]

# SiteController#redirect_combook
REDIRECT = {
  "1_welcome_to_git"                       => "en/Getting-Started",
  "1_the_git_object_model"                 => "en/Git-Internals-Git-Objects",
  "1_git_directory_and_working_directory"  => "en/Git-Basics-Recording-Changes-to-the-Repository",
  "1_the_git_index"                        => "en/Git-Basics-Recording-Changes-to-the-Repository",
  "2_installing_git"                       => "en/Getting-Started-Installing-Git",
  "2_setup_and_initialization"             => "en/Getting-Started-First-Time-Git-Setup",
  "3_getting_a_git_repository"             => "en/Git-Basics-Getting-a-Git-Repository",
  "3_normal_workflow"                      => "en/Git-Basics-Recording-Changes-to-the-Repository",
  "3_basic_branching_and_merging"          => "en/Git-Branching-Basic-Branching-and-Merging",
  "3_reviewing_history_-_git_log"          => "en/Git-Basics-Viewing-the-Commit-History",
  "3_comparing_commits_-_git_diff"         => "en/Git-Basics-Recording-Changes-to-the-Repository#Viewing-Your-Staged-and-Unstaged-Changes",
  "3_distributed_workflows"                => "en/Distributed-Git-Distributed-Workflows",
  "3_git_tag"                              => "en/Git-Basics-Tagging",
  "4_ignoring_files"                       => "en/Git-Basics-Recording-Changes-to-the-Repository#Ignoring-Files",
  "4_rebasing"                             => "en/Git-Branching-Rebasing",
  "4_interactive_rebasing"                 => "en/Git-Tools-Rewriting-History#Changing-Multiple-Commit-Messages",
  "4_interactive_adding"                   => "en/Git-Tools-Interactive-Staging",
  "4_stashing"                             => "en/Git-Tools-Stashing",
  "4_git_treeishes"                        => "en/Git-Tools-Revision-Selection",
  "4_tracking_branches"                    => "en/Git-Branching-Remote-Branches#Tracking-Branches",
  "4_finding_with_git_grep"                => "",
  "4_undoing_in_git_-_reset,_checkout_and_revert" => "en/Git-Basics-Undoing-Things",
  "4_maintaining_git"                      => "en/Git-Internals-Maintenance-and-Data-Recovery",
  "4_setting_up_a_public_repository"       => "en/Git-on-the-Server-Public-Access",
  "4_setting_up_a_private_repository"      => "en/Git-on-the-Server-Setting-Up-the-Server",
  "5_creating_new_empty_branches"          => "",
  "5_modifying_your_history"               => "en/Git-Tools-Rewriting-History",
  "5_advanced_branching_and_merging"       => "en/Git-Branching-Basic-Branching-and-Merging",
  "5_finding_issues_-_git_bisect"          => "en/Git-Tools-Debugging-with-Git#Binary-Search",
  "5_finding_issues_-_git_blame"           => "en/Git-Tools-Debugging-with-Git#File-Annotation",
  "5_git_and_email"                        => "en/Distributed-Git-Contributing-to-a-Project#Public-Large-Project",
  "5_customizing_git"                      => "en/Customizing-Git-Git-Configuration",
  "5_git_hooks"                            => "en/Customizing-Git-Git-Hooks",
  "5_recovering_corrupted_objects"         => "en/Git-Internals-Maintenance-and-Data-Recovery#Data-Recovery",
  "5_submodules"                           => "en/Git-Tools-Submodules",
  "6_git_on_windows"                       => "",
  "6_deploying_with_git"                   => "",
  "6_subversion_integration"               => "en/Git-and-Other-Systems-Git-and-Subversion",
  "6_scm_migration"                        => "en/Git-and-Other-Systems-Migrating-to-Git",
  "6_graphical_git"                        => "",
  "6_hosted_git"                           => "en/Git-on-the-Server-Hosted-Git",
  "6_alternative_uses"                     => "",
  "6_scripting_and_git"                    => "en/Customizing-Git-An-Example-Git-Enforced-Policy",
  "6_git_and_editors"                      => "",
  "7_how_git_stores_objects"               => "en/Git-Internals-Git-Objects",
  "7_browsing_git_objects"                 => "en/Git-Internals-Git-Objects",
  "7_git_references"                       => "en/Git-Internals-Git-References",
  "7_the_git_index"                        => "",
  "7_the_packfile"                         => "en/Git-Internals-Packfiles",
  "7_raw_git"                              => "en/Git-Internals-Git-Objects",
  "7_transfer_protocols"                   => "en/Git-Internals-Transfer-Protocols",
  "7_glossary"                             => "commands"
}

