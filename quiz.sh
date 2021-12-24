#!/bin/bash
# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# variables
PS3="> "
quiz_dir=(quiz_files/*)
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
}