#!/usr/bin/env bash
# colors
RED='\033[0;31m'
PROMPT_GREEN=$'\001\033[0;32m\002'
GREEN='\033[0;32m'
NC='\033[0m'

# variables
quiz_dir=(quiz_keys/*)
question_key=()
answer_key=()
q_index=-1
q_count=0
correct=0
wrong=0
no_response=0
skip=0
q_started=0

load_quiz_files() {
    # loop through all lines of quiz file and split keys into arrays
    quiz_file="$1"
    while IFS='|' read -ra line; do
        question_key+=("${line[0]}")
        answer_key+=("${line[1]}")
    done < "$quiz_file"
    # get number of questions from quiz file
    target_questions=$(wc -l < "$quiz_file" | xargs)
}

function display_header {
    clear -x
    printf '%b' "\nQUIZ SHELL\n"
    printf '%.s─' $(seq 1 "$(tput cols)")
}

function display_help {
    clear -x
    display_header
    printf "If using the included quizzes, separate your answers that have multiple parts with a comma(,) and a space( ).\n"
    printf '%b' "Example: ${GREEN}for, while, until${NC}\n"
    if (( q_started == 1 )); then 
        printf "\n"
        (( q_count-- ))
        (( q_index-- ))
        start_quiz
    else 
        display_menu
    fi
}

function display_menu {
    printf '%b' '(h)help  (q)quit\n\n'
    printf 'Choose your quiz below:\n'
    # print menu based on files in quiz directory
    for i in "${!quiz_dir[@]}"; do 
        printf "%d) %s\n" "$i" "${quiz_dir[i]#quiz_keys/}"
        (( i++ ))
    done
    local arr_len="${#quiz_dir[@]}"
    (( arr_len-- )) # subtract 1 from array arr_length for case statement below
    local prompt="Check an option (again to uncheck, ENTER when done): "
    local index
    read -rep "${prompt}" index 
    case "${index}" in 
            "h") display_help; [[ -z "${quiz_file}" ]] && display_menu 
                ;;
            "q") exit 100
                ;;
            (*[0-"${arr_len}"]*) load_quiz_files "${quiz_dir["${index}"]}" 
                ;;
            ("" | *[!0-"${arr_len}"]*) printf '%b' "Invalid selection\n"
                    read -rt 1 </dev/tty 3<&- 3<&0 <&3
                    display_header
                    display_menu
                ;;
    esac
}

function shuffle_questions {
    local i=0
    until (( i == target_questions ))
    do
        q_order+=( "${i}" )
        (( i++ ))
    done
    mapfile -t shuffled_order <<< "$( shuf -n "${target_questions}" -e "${q_order[@]}" )"
}

function check_quiz_end {
    if (( q_count < target_questions )); then 
        read -rt 1 </dev/tty 3<&- 3<&0 <&3
    elif (( q_count == target_questions )); then 
        exit 100
    fi
}
function start_quiz {
    until (( q_count == target_questions ))
    do
        [[ "${q_started}" -ne 1 ]] && display_header
        q_started=0
        (( q_count++ ))
        (( q_index++ ))
        current_index="${shuffled_order["${q_index}"]}"
        current_question="${question_key["${current_index}"]}"
        current_answer="${answer_key["${current_index}"]}"

        printf "(%s) %b\n" "${q_count}" "${current_question}"
        read -rp "Answer> ${PROMPT_GREEN}" -e response
        printf '%b' "${NC}"
        # disregard case in answer
        shopt -s nocasematch
            case "${response}" in 
            "${current_answer}") 
                printf '%b' "${GREEN}Awesome! That's the correct answer.${NC} " 
                (( correct++ ))
            ;; 
            "h") 
                q_started=1
                display_help 
            ;;
            "q") 
                exit 100
            ;;
            "skip")
                (( skip++ ))
                printf "Question skipped"
                if (( skip >= 3 ))
                then 
                    printf "You have skipped %s times now.\n" "${skip}"
                fi
            ;;
            *) 
                if [[ -z "${response}" ]]; then
                    printf '%b' "No response, ${RED}incorrect${NC}\n"
                    (( no_response++ ))
                    (( wrong++ ))
                        if (( no_response > 1 ))
                        then
                            printf '%b' "You have ${RED}${no_response}${NC} blank responses now\n" 
                        fi
                else
                    (( wrong++ ))
                        printf '%b' "${RED}That is incorrect${NC}\n"
                fi
            ;;
            esac
        check_quiz_end
    done
}

display_scorecard() {
    printf '%b' "${NC}"
    [[ -z "${quiz_file}" ]] && exit 0
    printf '%b' "\n"
    display_header
    printf "Quiz has ended! Let's see how you did..\n\n"
    read -rt 1 </dev/tty 3<&- 3<&0 <&3
    quiz_duration=$(( SECONDS - quiz_timer))
    if (( correct == target_questions )); then
        printf "\nAwesome! You got them all right in %s seconds.\n\n" "${quiz_duration}"
    elif (( no_response == target_questions )); then 
        printf "\nYou gave %s blank responses.\n\n" "${no_response}"                
    elif (( wrong ==  target_questions )); then
        printf "\nWomp Womp, You got them all wrong in %s seconds.\n\n" "${quiz_duration}"
    elif (( skip ==  target_questions )); then 
        printf "\nYou skipped all the questions.. uhhh?\n\n"             
    else
        printf "\nOut of (%s questions), you got " "${target_questions}"
        (( wrong > 0 )) && printf '%b' "${RED}(${wrong} wrong)${NC} and " 
        (( correct > 0 )) && printf '%b' "${GREEN}(${correct} correct)${NC} "
        if (( skip == 0 )); then
            printf "with no skips in a time of %s seconds.\n " "${quiz_duration}"
        elif (( skip >= 1)); then
            printf "with %s skips in a time of %s seconds.\n" "${skip}" "${quiz_duration}"
        fi
    fi
    exit 0
}

trap '[[ $? -eq 100 || 2 ]] && display_scorecard' EXIT
display_header
display_menu
shuffle_questions
quiz_timer=$SECONDS
start_quiz