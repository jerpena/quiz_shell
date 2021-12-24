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