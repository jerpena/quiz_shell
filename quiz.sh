#!/bin/bash
# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# variables
PS3="> "
quiz_dir=(quiz_keys/*)
question_key=()
answer_key=()
q_index=-1

function display_menu {
    echo ""
    echo "QUIZZ SHELL"
    echo "_________________________"
    echo "For answers that have multiple parts, separate them with a comma."
    echo  -e "Example: What are the 3 types of loops in bash scripting? ${GREEN}for, while, until${NC}"
    echo -e "\n"

    echo "Choose your quiz below (q to quit):"
    # select quiz and if anything other than the numbers of the files is chosen, exit script
    select opt in "${quiz_dir[@]}"
    do
        case "$opt" in
            "") echo "Exiting quiz..."
                exit 1 ;;
            *) quiz_file="$opt" 
                break;;
        esac
    done
    # loop through all lines of quiz file and split keys into arrays
    while IFS="|" read -ra line; do
	question_key+=("${line[0]}")
	answer_key+=("${line[1]}")
    done < "$quiz_file"
}