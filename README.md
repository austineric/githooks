
The contents of this repo allow the running of a PowerShell script as a git hook

This solves the following issues:
- Sometimes git hooks need scripting logic
- By default git hooks are not source-controlled

First within the project root create the directory .githooks
Then within the project run "git config core.hooksPath .githooks"
Then place the hook file into the .githooks directory and rename to the proper hook name (pre-commit, pre-push, etc)
