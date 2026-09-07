# Git Configuration Profile: Feature Reference Guide

This document provides a detailed breakdown of the highly optimized Git configuration file (`.gitconfig`). The file is engineered to streamline terminal workflows, enhance visualization of version history, enforce clean repository management, and introduce automation to common development sequences.

---

## 📦 Required Packages

To use this Git configuration along with its configured editor (`micro`) and pager on Debian-based systems:

```bash
sudo apt update
sudo apt install git micro less
```

## 🚀 Installation

### 1. Install the configuration with Stow

Run the following command to use `GNU stow` to take care of the configuration:

```bash
cd ~/.dotfiles
stow git
```

### 2. Configure the personal files

The `_template` files are intentionally not used directly by Git. Copy each
template to the filename Git expects, then customize the copied files. This
only creates the three personal files; Stow has already created the directory
structure:

```bash
cp ~/.config/git/.git_user_template ~/.config/git/.git_user
cp ~/.config/git/.git_ignore_global_template ~/.config/git/.git_ignore_global
cp ~/.config/git/.git_credentials_template ~/.config/git/.git_credentials
```

Replace the example name and email in `.git_user`, replace or add global
ignore patterns in `.git_ignore_global`, and replace the placeholder
credentials URL in `.git_credentials`. Edit them with `micro` (or any text
editor):

```bash
micro ~/.config/git/.git_user
micro ~/.config/git/.git_ignore_global
micro ~/.config/git/.git_credentials
```

The credentials file contains sensitive information and is stored in plain
text by Git's `store` credential helper. Keep it private and restrict its
permissions:

```bash
chmod 600 ~/.config/git/.git_credentials
```

---

## 1. Core Environment Settings (`[core]`, `[color]`, `[init]`, `[help]`)

These configurations modify Git's fundamental interaction with your operating system, text editor, and terminal output display.

### Text Editor & Terminal Paging
* **`editor = micro`**: Sets `micro` as the default terminal text editor for writing commit messages, interactive rebases, and merge tags. `micro` is a modern, intuitive terminal editor supporting familiar keyboard shortcuts (Ctrl+C, Ctrl+V, Ctrl+S) and native mouse support.
* **`pager = less -R`**: Instructs Git to pass log outputs and diffs through the `less` pager with the `-R` (raw control characters) flag. This forces long text lines to wrap naturally rather than chopping off the screen edge, while preserving full ANSI color rendering.
* **`ui = auto`**: Automatically activates color-coded text across terminal interfaces (`git status`, `git diff`, `git log`), tailoring colors depending on whether output goes directly to a terminal or a piped file.

### Initialization & Automation
* **`defaultBranch = main`**: Standardizes the default branch name as `main` for all newly initialized repositories via `git init`, matching modern industry standards and remote hosting conventions (such as GitHub and GitLab).
* **`autocorrect = 15`**: Adds a typo-protection buffer. If you mistype a command (e.g., `git stat`), Git will display a prompt indicating what command it thinks you meant and automatically execute it after a **1.5-second delay** (15 tenths of a second), allowing you time to hit `Ctrl+C` to abort if it's incorrect.

### Global File Exclusion
* **`excludesfile = ~/.config/git/.git_ignore_global`**: Links to a centralized, global gitignore file. Any rules listed here (such as OS-specific tracker files like macOS `.DS_Store`, Windows `Thumbs.db`, or local IDE configs like `.vscode/`) are ignored across **every repository** on your machine without requiring a local `.gitignore` entry in each project.

---

## 2. Security, Credentials & Modular Inclusion (`[include]`, `[credential]`)

Separating generic operational logic from sensitive identifiers ensures clean configurations across shared systems.

* **`path = ~/.config/git/.git_user`**: Implements modular configurations by pulling in an external file. This allows you to store personal or company-specific environment variables—such as `[user] name` and `email`—in a separate standalone file. It prevents personal identity leaks if you ever publicize your core dotfiles or share configuration templates.
* **`helper = store --file ~/.config/git/.git_credentials`**: Configures an encrypted or plain-text file storage credential helper located at a non-standard path. This tells Git to cache your remote HTTP/HTTPS authentication tokens locally after the first login sequence, preventing repetitive password prompts during pushes or pulls.

---

## 3. Remote Tracking & Conflict Resolution (`[push]`, `[pull]`, `[rebase]`, `[fetch]`, `[merge]`)

These directives override default Git protocols to prevent messy commit histories and simplify branch synchronizations.

### Automated Remote Handshakes
* **`autoSetupRemote = true`**: Removes the requirement to type `git push --set-upstream origin <branch-name>` when pushing a newly created local branch for the first time. Git will automatically establish tracking links with a remote branch of the identical name.
* **`default = simple`**: A safe push policy that protects upstream code. In central workflows, typing plain `git push` will only push the current active branch to its matching remote counterpart. If the branch names do not match, the transaction is rejected.

### Clean History Strategies
* **`rebase.autoStash = true`**: A protective companion for rebasing. If you have uncommitted or dirty changes in your working directory when running a rebase operation, Git will automatically run a hidden `git stash`, perform the rebase cleanly, and automatically pop/reapply your local modifications when finished.
* **`fetch.prune = true`**: Trims obsolete branches. When communicating with the remote server (`git fetch` or `git pull`), Git scans for tracking branches that have been deleted or merged on the server side and deletes their corresponding local stale references (`origin/feature-xyz`).

### Advanced Conflict Resolution
* **`conflictstyle = zdiff3`**: Upgrades standard conflict markers to the advanced `zdiff3` layout. While standard Git displays what your branch has vs. what their branch has, `zdiff3` goes a step further by showing a third block: the **common base commit** before both tracks split, while compressing identical matching regions. This provides complete structural context to determine exactly why and how code drifted apart.

---

## 4. Productivity Aliases (`[alias]`)

The `[alias]` block introduces severe shorthand shortcuts and shell macro functions to abstract away verbose git commands.

### The Essentials
These map basic git workflows to immediate 2-letter keystrokes.

| Alias | Full Git Command | Functional Description |
| :--- | :--- | :--- |
| `st` | `status -sb` | Displays a highly compressed, readable project status including explicit branch head-tracking info. |
| `co` | `checkout` | Traditional utility to switch branches or restore working tree files. |
| `br` | `branch` | Lists, creates, or deletes local branches. |
| `ci` | `commit` | Records snapshot changes to the repository history. |
| `sw` | `switch` | Modern, explicit alternative to `checkout` focused entirely on changing branch contexts. |
| `rs` | `restore` | Modern, dedicated replacement to `reset` focused exclusively on discarding uncommitted modifications. |

### Visual Log Magic
* **`lg`**: A premium log visualizer that constructs a beautifully colorized, topological graph of your version history inside the terminal panel.
    * *Full string expression:* `log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit`
    * *Output details:* Renders short commit hashes in red, branch tags/remotes in yellow, commit subjects in white, relative timestamps (e.g., *2 hours ago*) in green, and author names in bold blue, all tied together alongside visual branch lines (`*`, `|`, `/`).
* **`last`**: Executes `log -1 HEAD`. Isolates and prints only the single most recent commit metadata details on your current active branch.

### Staging, Unstaging & Committing Macros
* **`ac`**: Shell execution function macro (`!git add -A && git commit -m`). Allows you to stage all tracking/untracked files and commit them with an inline message via a single unified command phrase:
    ```bash
    git ac "Refactored user login verification engine"
    ```
* **`up`**: Shell execution function macro (`!git add . && git commit && git push`). Automatically stages all modifications in the current directory, opens your default editor `(micro)` to let you write a commit message, and immediately pushes the branch to your remote repository in a single, streamlined sequence:
    ```bash
    git up
    ```
* **`amend`**: Executes `commit --amend --no-edit`. Instantly injects newly staged changes straight into the previous commit block without spawning an editor or modifying the existing log title message.
* **`amend-message`**: Executes `commit --amend`. Appends newly staged adjustments into your last commit while explicitly prompting open your text editor (`micro`) to modify the commit message.
* **`uncommit`**: Executes `reset --soft HEAD~1`. Safely undoes the last commit on your active branch, reverting your repository index state back by one step while leaving all modified codes and files fully intact in your current staging environment.
* **`unstage`**: Maps to `restore --staged`. Removes a specific, targeted file away from your staging environment while protecting its literal disk modifications. Use case: `git unstage index.js`.
* **`unstage-all`**: Maps to `restore --staged .`. Instantly resets your entire staging directory workspace back to an unstaged state in one clear sweep.

### Environment Cleanup Automation
* **`cleanup`**: A shell-piped scripting sequence designed to keep local environments free of bloat.
    * *Full execution formula:* `!git branch --merged | grep -v '\*' | xargs -n 1 git branch -d`
    * *Functional breakdown:* Queries all local branches that have already been fully merged into your active branch, filters out your current checked-out branch via inversion (`grep -v '\*'`), and pipes those remaining target strings cleanly into individual delete arguments (`xargs -n 1 git branch -d`). This cleans out obsolete feature branches locally in one run.
