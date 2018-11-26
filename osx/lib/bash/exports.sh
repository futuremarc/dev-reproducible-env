#!/bin/bash

# Editors
export EDITOR='nano'
export VISUAL=${EDITOR}

export PREVIEW="/Applications/Preview.app"

# Prompts
export PS2="❯"
export PS3="[?]"

# History control
export HISTIGNORE='history:ls:ls *:date:w:man *:reload'
export HISTCONTROL='ignoredups:erasedups'

# Increase Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE='32768'
export HISTFILESIZE="${HISTSIZE}"

# Prefer US English and use UTF-8.
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Enable color support of ls
export CLICOLOR=1
export LSCOLORS=gxfxcxdxbxxxxxxxxxexex

# PROMPT TRIM
export PROMPT_DIRTRIM=2

export LINES=128

# Don’t clear the screen after quitting a manual page.
export MANPAGER='less -X'

# Extend PATH
PATH="/usr/local/sbin:$HOME/bin:$PATH"

# CLEAN PATH
PATH=$(awk -F: '{for(i=1;i<=NF;i++){if(!($i in a)){a[$i];printf s$i;s=":"}}}' <<<"$PATH")
export PATH

# add support for ctrl+o to open selected file in VS Code
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(${CODE_EDITOR} {})+abort'"
export FZF_DEFAULT_COMMAND="fd --type f"
