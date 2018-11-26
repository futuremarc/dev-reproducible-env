#!/bin/bash

subshell_minus_vscode() {
	local result=1
	if [ "$SHLVL" -eq 1 ]; then result=0; fi
	if [ "$SHLVL" -eq 2 ] && [ "$TERM_PROGRAM" == "vscode" ]; then result=0; fi
	echo $result
}

prompt() {

	local EXIT="$?"

	local prompt_symbol='🚀 '
	local tab_name='\W'

	local reset='\[\e[0m\]'
	local bold='\[\e[1m\]'
	local dim='\[\e[2m\]'
	local red='\[\e[31m\]'
	local green='\[\e[32m\]'
	local yellow='\[\e[33m\]'
	local cyan='\[\e[36m\]'
	local white='\[\e[37m\]'

	local user_color="$yellow"
	local host_tyle="$green"
	local exit_color="$green"

	# If a package.json on the WD, use the package name as the WD
	if [ -f ./package.json ]; then
		tab_name="$(jq '.name' <./package.json | sed -e 's/\"//g') "
	fi

	if [ "$(subshell_minus_vscode)" -eq 1 ]; then
		prompt_symbol="$ ❯"
	fi

	# Highlight the hostname when connected via SSH.
	if [ -n "$SSH_TTY" ]; then
		host_tyle="$bold$green"
		tab_name="\\h - $tab_name"
	fi

	# Highlight the user name when logged in as root.
	if [ "$EUID" -eq 0 ]; then user_color="$bold$red"; fi

	# Set the lambda as red if last comand exited with non 0
	if [ $EXIT != 0 ]; then exit_color="$red"; fi

	set_tab_name() {
		local isXterm=0
		case $TERM in
		xterm*) isXterm=1 ;;
		*) isXterm=0 ;;
		esac
		if [ $isXterm -eq 1 ]; then printf '\e]1;%s\a' "$tab_name"; fi
	}

	prompt_git() {
		local branch_name=""

		get_git_branch() {
			git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo '(unknown)'
		}

		is_branch1_behind_branch2() {
			# Find the first log (if any) that is in branch1 but not branch2
			first_log="$(git log "$1..$2" -1 2>/dev/null)"

			# Exit with 0 if there is a first log, 1 if there is not
			[[ -n "$first_log" ]]
		}

		branch_exists() {
			# List remote branches           | # Find our branch and exit with 0 or 1 if found/not found
			git branch --remote 2>/dev/null | grep --quiet "$1"
		}

		parse_git_ahead() {
			# Grab the local and remote branch
			branch="$(get_git_branch)"
			remote="$(git config --get "branch.${branch}.remote" || echo -n "origin")"
			remote_branch="$remote/$branch"

			# If the remote branch is behind the local branch        || or it has not been merged into origin (remote branch doesn't exist)
			if (is_branch1_behind_branch2 "$remote_branch" "$branch" || ! branch_exists "$remote_branch"); then
				echo 1
			fi
		}

		parse_git_behind() {
			# Grab the branch
			branch="$(get_git_branch)"
			remote="$(git config --get "branch.${branch}.remote" || echo -n "origin")"
			remote_branch="$remote/$branch"
			# If the local branch is behind the remote branch
			if is_branch1_behind_branch2 "$branch" "$remote_branch"; then
				echo 1
			fi
		}

		parse_git_dirty() {
			# If the git status has *any* changes (e.g. dirty), echo our character
			if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
				echo 1
			fi
		}

		get_git_status() {

			output="$bold"

			if [[ "$dirty_branch" == 1 ]]; then
				synced_symbol="● $branch_name"
				unpushed_symbol="▲ $branch_name"
				unpulled_symbol="▼ $branch_name"
				unpushed_unpulled_symbol="⬢ $branch_name"
			else
				synced_symbol="◎ $branch_name"
				unpushed_symbol="△ $branch_name"
				unpulled_symbol="▽ $branch_name"
				unpushed_unpulled_symbol="⬡ $branch_name"
			fi

			if [[ "$branch_ahead" == 1 && "$branch_behind" == 1 ]]; then
				output+="$red$unpushed_unpulled_symbol"
			elif [[ "$branch_behind" == 1 ]]; then
				output+="$yellow$unpulled_symbol"
			elif [[ "$branch_ahead" == 1 ]]; then
				output+="$cyan$unpushed_symbol"
			else
				output+="$green$synced_symbol"
			fi

			echo -e "$reset$output$reset"
		}

		# Check if the current directory is in a Git repository.
		if [ "$(
			git rev-parse --is-inside-work-tree &>/dev/null
			echo "${?}"
		)" == '0' ]; then

			branch_name="$(get_git_branch)"

			# check if the current directory is in .git before running git checks
			if [ "$(git rev-parse --is-inside-git-dir 2>/dev/null)" == 'false' ]; then
				# Ensure the index is up to date.
				git update-index --really-refresh -q &>/dev/null

				dirty_branch="$(parse_git_dirty)"
				branch_ahead="$(parse_git_ahead)"
				branch_behind="$(parse_git_behind)"

				echo -e " $(get_git_status)"
			else
				echo -e " $reset$branch_name$reset"
			fi

		else

			return
		fi
	}

	PS1="$(set_tab_name)"

	PS1+="$reset$user_color\\u"
	PS1+="$reset$dim$white:"
	PS1+="$reset$host_tyle\\h"

	PS1+="$reset$dim$white in "
	PS1+="$reset$white\\w"

	PS1+="$(prompt_git)" # Git repository details

	PS1+="$reset"

	PS1="$PS1\\n$reset$exit_color$prompt_symbol$reset "

	# Update bash_history
	history -a
	history -c
	history -r

	# Update Columns and lines just in case
	# shellcheck disable=SC2155
	export COLUMNS=$(tput cols)
	# shellcheck disable=SC2155
	export LINES=$(tput lines)
	export PS1
}

# If on a subshell do not inherit the PROMPT_COMMAND
if [ "$(subshell_minus_vscode)" -eq 1 ]; then
	PROMPT_COMMAND="prompt"
else
	PROMPT_COMMAND="prompt; $PROMPT_COMMAND"
fi

PROMPT_COMMAND=$(awk -F\; '{for(i=1;i<=NF;i++){if(!($i in a)){a[$i];printf s$i;s=";"}}}' <<<"$PROMPT_COMMAND")

export PROMPT_COMMAND
