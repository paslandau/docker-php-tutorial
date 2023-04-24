export PS1='$(whoami):$(pwd)# '
alias ll='ls -l'
alias ls='ls --color=auto'

# see https://stackoverflow.com/questions/4188324/bash-completion-of-makefile-target
# -h to grep to hide filenames
# -s to grep to hide error messages
# include Makefile and .make directory
complete -W "\`grep -shoE '^[a-zA-Z0-9_.-]+:([^=]|$)' ?akefile .make/*.mk | sed 's/[^a-zA-Z0-9_.-]*$//' | grep -v PHONY\`" make