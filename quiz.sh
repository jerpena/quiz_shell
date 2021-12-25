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
q_count=0
correct=0
wrong=0
no_response=0
skip=0

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
    while IFS="|" read -ra line
    do
        question_key+=("${line[0]}")
        answer_key+=("${line[1]}")
    done < "$quiz_file"
    # get number of questions from quiz file
    target_questions=$(wc -l <$quiz_file | xargs)
}

function shuffle_questions {
    local i=0
    until ((i == $target_questions))
    do
        q_order+=($i)
        ((i++))
    done
    echo ${q_order[@]}
    shuffled_order=( $(shuf -n${target_questions} -e ${q_order[@]}) )
}

function check_quiz_end {
    if (($q_count < $target_questions))
    then 
        printf "On to the next question!\n\n"
        sleep 1
    else
        printf "\nQuiz completed! Let's see how you did...\n"
        sleep 1
    fi
}

function start_quiz {
    until ((q_count == target_questions))
    do
        ((q_count++))
        ((q_index++))
        current_index=$( echo ${shuffled_order[$q_index]})
        current_question="${question_key[$current_index]}"
        current_answer="${answer_key[$current_index]}"

        printf "(${q_count}) ${current_question}? "
        echo -e -n "${GREEN}"
        read response
        echo -e -n "${NC}"
        # disregard case in answer
        shopt -s nocasematch
            case $response in 
            "$current_answer") 
                printf "${GREEN}Awesome! That's the correct answer.${NC} " 
                ((correct++))
                check_quiz_end
            ;; 
            q) 
                printf "\nExiting quiz...\n"
                break
            ;;
            "skip")
                ((skip++))
                printf "Skipping question.."
                if ((skip >= 3))
                then 
                    printf "You have skipped ${skip} times now.\n"
                fi
                check_quiz_end
            ;;
            *) 
                if [[ -z ${response} ]]
                then
                    printf "You didn't provide an answer! "
                    ((no_response++))
                    ((wrong++))
                        if (( no_response > 1 ))
                        then
                            printf "You have ${no_response} blank responses so far. \n"   
                        fi
                else
                    ((wrong++))
                        printf "${RED}That is incorrect...${NC}\n\n"
                fi
                check_quiz_end
            ;;
            esac
    done
}

display_menu
shuffle_questions
quiz_timer=$SECONDS
start_quiz