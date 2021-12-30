#!/bin/bash
# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# variables
PS3='> '
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
    echo "If using the included quizzes separate answers that have multiple parts with (, )"
    echo -e "Example: What are the 3 types of loops in bash scripting? ${GREEN}for, while, until${NC}"
    echo -e "\n"

    echo 'Choose your quiz below (q to quit):'
    # select quiz and if anything other than the numbers of the files is chosen, exit script
    select opt in "${quiz_dir[@]}"
    do
        case "$opt" in
            "") echo 'Exiting quiz...'
                exit 1 ;;
            *) quiz_file="$opt" 
                break;;
        esac
    done
    # loop through all lines of quiz file and split keys into arrays
    while IFS='|' read -ra line
    do
        question_key+=("${line[0]}")
        answer_key+=("${line[1]}")
    done < "$quiz_file"
    # get number of questions from quiz file
    target_questions=$(wc -l < "$quiz_file" | xargs)
    # add space between menu and questions
    printf "\n"
}

function shuffle_questions {
    local i=0
    until (( i == "$target_questions" ))
    do
        q_order+=( "$i" )
        (( i++ ))
    done
    mapfile -t shuffled_order <<< "$( shuf -n "$target_questions" -e "${q_order[@]}" )"
}

function check_quiz_end {
    if (( q_count < target_questions )); then 
        printf "\nOn to the next question!\n\n"
        sleep 1
    elif (( q_count == target_questions )); then 
        printf "\nQuiz has ended! Let's see how you did..\n\n"
        sleep 2
        quiz_duration=$(( SECONDS - quiz_timer))
        if (( correct == target_questions )); then
            printf "\nAwesome! You got them all right in %s seconds.\n\n" "$quiz_duration"
        elif (( no_response == target_questions )); then 
            printf "\nYou gave %s blank responses.\n\n" "$no_response"                
        elif (( wrong ==  target_questions )); then
            printf "\nWomp Womp, You got them all wrong in %s seconds.\n\n" "$quiz_duration"
        elif (( skip ==  target_questions )); then 
            printf "\nYou skipped all the questions.. uhhh?\n\n"             
        else
            printf "\nOut of (%s questions), you got " "$target_questions"
            (( wrong > 0 )) && printf '%b' "${RED}($wrong wrong)${NC} and " 
            (( correct > 0 )) && printf '%b' "${GREEN}(${correct} correct)${NC} "
            if (( skip == 0 )); then
                printf "with no skips in a time of %s seconds.\n " "$quiz_duration"
            elif (( skip >= 1)); then
                printf "with %s skips in a time of %s seconds.\n" "$skip" "$quiz_duration"
            fi
        fi
    fi
}

function start_quiz {
    until (( q_count == target_questions ))
    do
        (( q_count++ ))
        (( q_index++ ))
        current_index="${shuffled_order[$q_index]}"
        current_question="${question_key[$current_index]}"
        current_answer="${answer_key[$current_index]}"

        printf "(%s) %b\nAnswer> " "$q_count" "$current_question"
        printf '%b' "${GREEN}"
        read -r response
        printf '%b' "${NC}"
        # disregard case in answer
        shopt -s nocasematch
            case $response in 
            "$current_answer") 
                printf '%b' "${GREEN}Awesome! That's the correct answer.${NC} " 
                (( correct++ ))
                check_quiz_end
            ;; 
            q) 
                printf "\nExiting quiz...\n"
                break
            ;;
            "skip")
                (( skip++ ))
                printf "Skipping question.."
                if (( skip >= 3 ))
                then 
                    printf "You have skipped %s times now.\n" "$skip"
                fi
                check_quiz_end
            ;;
            *) 
                if [[ -z ${response} ]]
                then
                    printf '%b' "You didn't provide an answer! Counting this one as ${RED}incorrect${NC}\n"
                    (( no_response++ ))
                    (( wrong++ ))
                        if (( no_response > 1 ))
                        then
                            printf '%b' "You have ${RED}$no_response${NC} blank responses so far.\n" 
                        fi
                else
                    (( wrong++ ))
                        printf '%b' "${RED}That is incorrect...${NC}\n\n"
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