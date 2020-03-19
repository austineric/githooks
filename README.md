
The contents of this repo allow a git hook to be replaced with the hook file (renamed to the appropriate git hook name), which then calls the specified PowerShell script

This solves the following issues:
- Sometimes git hooks need somewhat extensive scripting logic, and hooks are not source-controlled
- Issues can arise due to line-ending differences (git hooks are by default unix-style)

This allows a simple, reusable hook script which calls a source-controlled PowerShell script
- The hook script calls a relative path to the PowerShell script and can handle filepaths with spaces
- The PowerShell script can use Windows-style line-endings which prevents any messiness in the repo
