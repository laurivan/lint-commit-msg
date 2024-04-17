![lint-commit-msg logo](doc/logo.png)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://choosealicense.com/licenses/mit)
[![Unit tests](https://img.shields.io/github/actions/workflow/status/laurivan/lint-commit-msg/test.yml?logo=Github&label=test&cacheSeconds=600)](https://github.com/laurivan/lint-commit-msg/actions/workflows/test.yml)
[![Releases](https://img.shields.io/github/v/release/laurivan/lint-commit-msg)](https://github.com/laurivan/lint-commit-msg/releases)
[![Runs on Bash version 3 and higher](https://img.shields.io/badge/Bash-%E2%89%A53-blue?logo=GNU%20Bash)](https://www.gnu.org/software/bash/)

---
<br/>

`lint-commit-msg` checks that a Git commit message follows
[a set of formatting and stylistic conventions](https://cbea.ms/git-commit/#seven-rules).
It is intended to be used in Git `commit-msg` hook.

```
$ git commit -m "add first version of REST client and instructions how to use it with HTTPS"
ERROR: commit message not properly formatted
- line 1: subject line too long (74), max length is 60
- line 1: subject not capitalized
  add first version of REST client and instructions how to use it with HTTPS

Continue anyway? [yes/no] no
Aborting commit!
Commit message saved in .git/lint-commit-msg.MSG
$
```

## Quick start
1. [Download](https://github.com/laurivan/lint-commit-msg/releases/latest/download/lint-commit-msg) the latest release of the script, make it executable, and put in your `PATH`.
1. Call it in your [commit-msg hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) like this
   ```
   lint-commit-msg "$1" || exit
   ```
1. Run `lint-commit-msg --help` for usage examples
   and information about configuration options.

## Contents
- [Installation](#installation)
- [Basic usage](#basic-usage)
- [Using in `commit-msg` hook](#using-in-commit-msg-hook)
- [Advanced usage and configuration](#advanced-usage-and-configuration)
  - [General settings](#general-settings)
  - [Modifying rules](#modifying-rules)
  - [Ignoring rules](#ignoring-rules)
- [Examples](#examples)
  - [Running standalone](#running-standalone-outside-commit-msg-hook)
  - [Using inside commit-msg hook](#using-inside-commit-msg-hook)
- [Tips](#tips)

## Installation
Download the script and make it executable.
```sh
curl -L https://github.com/laurivan/lint-commit-msg/releases/latest/download/lint-commit-msg > lint-commit-msg
chmod u+x lint-commit-msg
```

## Basic usage
You can test the script by linting a commit message written in a file.
If there are errors in the commit message the script returns a non-zero exit code.
```sh
cat > test-message.txt <<EOF
This is the subject line of my commit

And here's the body.
EOF
./lint-commit-msg test-message.txt || echo "Failed"
```

### Using in `commit-msg` hook
To lint your commit messages automatically you can call the script in your
Git repository's `commit-msg` hook. For this, there are a couple of approaches.

#### Method 1: Add to PATH
1. Move `lint-commit-msg` somewhere in your PATH.
   ```sh
   mv lint-commit-msg ~/bin
   ```
2. Add this line to your commit-msg hook which is by default `my-repo/.git/hooks/commit-msg`.
   ```sh
   lint-commit-msg "$1" || exit
   ```
   If the file doesn't exist you can create it and make it executable.
   ```sh
   cat > my-repo/.git/hooks/commit-msg <<EOF
   #!/bin/sh

   lint-commit-msg "$1" || exit
   EOF
   chmod u+x my-repo/.git/hooks/commit-msg
   ```

#### Method 2: Add to repository
If you want to distribute your hooks to anyone who clones the repository
you can add `lint-commit-msg` to your repository and call it using a relative path:
1. Add `commit-msg` hook and `lint-commit-msg` to your repository.
   ```sh
   mkdir my-repo/hooks
   cp lint-commit-msg my-repo/hooks
   cat > my-repo/hooks/commit-msg <<EOF
   #!/bin/sh

   hooks/lint-commit-msg "$1" || exit
   EOF
   chmod u+x my-repo/hooks/*
   ```
2. Configure Git to use the `hooks` directory.
   This step has to be done by anyone who clones the repository.
   ```sh
   cd my-repo
   git config core.hooksPath hooks
   ```

That's it!
`lint-commit-msg` will now check your commit messages
and let you either fix or ignore the potential errors.
```
$ git commit -m "created README file"
ERROR: commit message not properly formatted
- line 1: subject not capitalized
- line 1: verb 'created' in the subject not in imperative mood,
          use for example 'Add' instead of 'Added'
  created README file

Continue anyway? [yes/no] no
Aborting commit!
Commit message saved in .git/lint-commit-msg.MSG
$ git commit -m "Create README file"
lint-commit-msg: commit message OK
[main 15d6555] Create README file
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
```

## Advanced usage and configuration
First, lint-commit-msg has sensible defaults so you can probably just start
using it with minimal tweaking.
That being said, `lint-commit-msg` is highly customizable which
is achieved using environment variables either _per invocation_
```sh
LCM_IGNORE_SUBJECT_NOT_CAPITALIZED=true git commit ...
```
or more permanently by exporting the variables for example in the startup files of the user's shell.
```sh
# ~/.bashrc
export LCM_INTERACTIVE=never
export LCM_SUBJECT_LINE_MAX_LENGTH=55
```

There are three categories of configuration:
[general settings](#general-settings), variables for [modifying the linting rules](#modifying-rules), and variables for [ignoring them](#ignoring-rules).
The following sections describes each configuration variable and
[Examples](#examples) gives guidance on how to use them.

### General settings

| Environment variable | Description | Default value |
| ---------------------| ----------- | ------------- |
| `LCM_INTERACTIVE` | Allow the user to choose interactively whether to ignore the reported errors. Options: `always`, `never`, `auto`. Using `auto` will enable interactive mode if lint-commit-msg is run as part of commit-msg hook AND stdout is terminal. Note that `always` is hardly ever what you want and doesn't play along well when committing from an IDE. | `auto` |
| `LCM_COLOR` | Whether to use colored output. Options: `always`, `never`, `auto`. With `auto` colors are used if printing to terminal). | `auto` |

The variables above will also accept values `true` (alias for `always`) and `false` (alias for `never`).

### Modifying rules

| Environment variable | Description | Default value |
| ---------------------| ----------- | ------------- |
| `LCM_SUBJECT_LINE_MAX_LENGTH` | Maximum length of the subject line (the first line). | `60` |
| `LCM_SUBJECT_LINE_MIN_LENGTH` | Minimum length of the subject line (the first line). | `3` |
| `LCM_BODY_LINE_MAX_LENGTH` | Maximum length of a line in the message body. | `72` |
| `LCM_SUBJECT_LINE_PREFIX_REGEX` | A POSIX extended regular expression that the **start** of the subject line should match. (That is, don't prefix the regex with `^` character.)  | `""` |
| `LCM_SUBJECT_LINE_PREFIX_HELP` | A custom help message to display if the start of the subject line doesn't match `LCM_SUBJECT_LINE_PREFIX_REGEX`. By default, a somewhat technical, and not that helpful, error message "subject line does not match regex..." is displayed. This variable can be set to provide a more user-friendly message. | `""` |

Note that the part of the subject line that matches `LCM_SUBJECT_LINE_PREFIX_REGEX`
is not taken into account when checking whether the subject is capitalized and whether (the first word of) the subject is in imperative mood (see `LCM_IGNORE_SUBJECT_NOT_CAPITALIZED` and `LCM_IGNORE_SUBJECT_MOOD` in the next section).
For example, some software teams have a convention of putting an issue ID in the beginning of the subject line:
```
DCL-5332 remove redundant SQL tables
```
Because the first character of the subject line is the capital `D`
the message would not raise a linting error
even though the actual subject "remove redundant SQL tables" is not capitalized.
The solution is to use
```sh
LCM_SUBJECT_LINE_PREFIX_REGEX='DCL-[1-9][0-9]* '
# or more generally
LCM_SUBJECT_LINE_PREFIX_REGEX='[A-Z][A-Z0-9]*-[1-9][0-9]* '
# or if the issue ID is optional
LCM_SUBJECT_LINE_PREFIX_REGEX='([A-Z][A-Z0-9]*-[1-9][0-9]* )?'
```
Now the subject line prefix is matched against the regular expression
and the actual subject is checked to start with an uppercase letter.

### Ignoring rules
Variables in the table below can be set to `true` to ignore certain (or all) errors.
Setting them to `false` is equivalent to not having them set at all.

| Environment variable | Effect (when variable set to "true") |
| -------------------- | --------------------------- |
| `LCM_IGNORE_ALL` | Ignore all linting rules. This effectively skips the linting. |
| `LCM_IGNORE_SUBJECT_LINE_TOO_SHORT` | Allow too short subject line. This rule is mostly for preventing accidental commits with a message of one or two characters. |
| `LCM_IGNORE_SUBJECT_LINE_TOO_LONG` | Allow too long subject line. The default maximum length for the subject line is 60 characters. |
| `LCM_IGNORE_SUBJECT_LINE_ENDS_IN_PERIOD` | Allow subject line to end in a period. |
| `LCM_IGNORE_SUBJECT_NOT_CAPITALIZED` | Allow subject to start with a lowercase letter. |
| `LCM_IGNORE_INVALID_SUBJECT_LINE_PREFIX` | Allow subject line _not_ to start with the configured subject line prefix regex. |
| `LCM_IGNORE_SUBJECT_MOOD` | Don't check that the first word of the subject is (a verb) in imperative mood. Note that this rule uses a simple heuristic of checking that the first word of the subject does not end in `s`, `ed`, or `ing` (for example `adds`, `added`, or `adding`). The user is adviced to simply ignore the rare false positives. |
| `LCM_IGNORE_BODY_LINE_TOO_LONG` | Allow too long lines in the body of the commit message. |
| `LCM_IGNORE_TABS` | Allow the commit message to contain tab characters. |
| `LCM_IGNORE_TRAILING_WHITESPACE` | Allow the commit message to contain trailing whitespace. |
| `LCM_IGNORE_MISSING_FINAL_EOL` | Allow the commit message to end with a character other than an [EOL](https://en.wikipedia.org/wiki/Newline) |
| `LCM_IGNORE_2ND_LINE_NOT_BLANK` | Allow the 2nd line of the commit message contain text. |
| `LCM_IGNORE_LINE_COUNT_IS_2` | Allow the commit message to be two lines long. |

## Examples
### Running standalone (outside commit-msg hook)
```sh
# Print usage instructions
lint-commit-message -h
# OR
lint-commit-message --help

# Lint commit message in a file
lint-commit-message msg.txt

# Lint commit message before committing
lint-commit-message msg.txt && git commit --file msg.txt

# The same as above but wrapped in a shell function
lintedcommit() {
   local msg_file="$1"; shift
   lint-commit-message "${msg_file}" && commit --file "${msg_file}" "$@"
}
lintedcommit msg.txt

# Read from stdin
cat msg.txt | lint-commit-msg
# Lint the message of an existing commit
git log -n1 --format=format:%B HEAD | lint-commit-msg

# Modify behaviour for a single invocation
LCM_IGNORE_SUBJECT_MOOD=true LCM_BODY_LINE_MAX_LENGTH=80 lint-commit-msg msg.txt
```

### Using inside commit-msg hook
The examples below show the contents of commit-msg hook (by default `.git/hooks/commit-msg`).
```sh
# Use with default configuration
lint-commit-msg "$1" || exit
```
```sh
# Allow longer lines
export LCM_SUBJECT_LINE_MAX_LENGTH=80
export LCM_BODY_LINE_MAX_LENGTH=80
lint-commit-msg "$1" || exit
```
```sh
# Ignore line length restrictions
export LCM_IGNORE_SUBJECT_LINE_TOO_SHORT=true
export LCM_IGNORE_SUBJECT_LINE_TOO_LONG=true
export LCM_IGNORE_BODY_LINE_TOO_LONG=true
lint-commit-msg "$1" || exit
```
```sh
# Require issue ID (e.g. "DCL-1122", "K8SU-13") at the beginning of the subject line.
export LCM_SUBJECT_LINE_PREFIX_REGEX='[A-Z][A-Z0-9]*-[1-9][0-9]* '
export LCM_SUBJECT_LINE_PREFIX_HELP='Subject line should start with the issue ID e.g. "DCL-1122 Fix JWT handling"'
lint-commit-msg "$1" || exit
```
```sh
# Expect an optional issue ID in the subject line. The regex will match any
# message and therefore has no direct effect on the linting. However, without
# it a message like
#   DCL-1533 add missing SQL tables
# would be (erroneously) considered valid even though the subject
# "add missing SQL tables" is not capitalized.
export LCM_SUBJECT_LINE_PREFIX_REGEX='([A-Z][A-Z0-9]*-[1-9][0-9]* )?'
lint-commit-msg "$1" || exit
```
```sh
# Require "conventional commit message" style subject lines with two possible
# scopes: "backend" and "frontend". (See https://www.conventionalcommits.org)
# Requires a subject like "fix(backend)!: Rename purchase API input params"
export LCM_SUBJECT_LINE_PREFIX_REGEX='(fix|feat|build|chore|ci|docs|style|refactor|perf|test)(\((backend|frontend)\))?!?: '
lint-commit-msg "$1" || exit
```
```sh
# Specify default values (different from internal defaults of lint-commit-msg)
# but in a way that allows the user to override them when invoking 'git commit'
: ${LCM_SUBJECT_LINE_MAX_LENGTH:=50}
: ${LCM_BODY_LINE_MAX_LENGTH:=80}
export LCM_SUBJECT_LINE_MAX_LENGTH LCM_BODY_LINE_MAX_LENGTH
lint-commit-msg "$1" || exit
# This allows the user to run e.g.
#   LCM_BODY_LINE_MAX_LENGTH=72 git commit ...
```

## Tips
### It's okay to ignore errors
The purpose of lint-commit-msg is to _help you_ make your commit messages more usable;
not to earn you a medal for achieving 100% error-free linting results.
If you think a linting error is a false positive simply ignore it.
If you think fixing an error reported by lint-commit-msg would not make your message more readable just disregard it.

A commit message is linted only once.
It's not like a compilation warning that you see with every build until you fix it.
```
$ git commit -m "Add unit tests for GET, POST, PUT, etc."
ERROR: commit message not properly formatted
- line 1: subject line ends in a period (.)
  Add unit tests for GET, POST, PUT, etc.

Continue anyway? [yes/no] yes
```
