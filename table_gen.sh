#!/usr/bin/env bash

# Box drawing characters:
horizontal="\xE2\x94\x80"
vertical="\xE2\x94\x82"
down_and_right="\xE2\x94\x8C"
down_and_left="\xE2\x94\x90"
up_and_right="\xE2\x94\x94"
up_and_left="\xE2\x94\x98"
vertical_and_right="\xE2\x94\x9C"
vertical_and_left="\xE2\x94\xA4"
horizontal_and_down="\xE2\x94\xAC"
horizontal_and_up="\xE2\x94\xB4"
vertical_and_horizontal="\xE2\x94\xBC"

declare -a input
declare -a alignment
declare -a column_size

file=""
header_line=false

bold=$(tput bold)
normal=$(tput sgr0)

parse_args() {
	if (( "$#" >= 1 )); then
		file=("$@")
	else
		printf '%b' "${bold}tbl.sh Usage:${normal} Call this file with a markdown " \
			"formatted array like below.\n" | fold -s
		printf '%s' "table=( '| Header  | Header  |' '| ------- | ------- |' " \
			"'| Row 1   | Row 1   |' )"
		printf '%b' '\n\n\nRefer to: https://www.markdownguide.org/extended-syntax/#tables\n'
		exit 1
	fi
	
}

check_encoding() {
	if ! (locale | grep -e 'utf8' -e 'UTF-8') &>/dev/null; then
		exit 2
	fi
}

read_input() {
	local index=0
	while IFS= read -r line; do
		line="${line#"|"}" #remove first pipe
		line="${line%"|"}" #remove last pipe
		input[$index]="$line"
		index=$((++index))
	done < <(printf '%s\n' "${file[@]}")
}
parse_input() {
	if ((${#input[@]} >= 2)); then
		if [[ "${input[1]}" =~ ^([[:space:]]*[-:]+[[:space:]]+\|)*([[:space:]]*[-:]+[[:space:]]*)+$ ]]; then
			header_line=true
			set_alignment "${input[1]}"
			input=("${input[@]/${input[1]}/}")
		fi
	fi
	set_column_size
}

set_alignment() {
	IFS='|' read -ra row <<<"$@"
	local index=0
	for i in "${row[@]}"; do
		i=$(strip "$i")
		local first="${i:0:1}"
		local last="${i:$((${#i} - 1)):1}"
		if [[ "$first" == ":" && "$last" == ":" ]]; then
			alignment[$index]="center"
		elif [[ "$first" == "-" && "$last" == ":" ]]; then
			alignment[$index]="right"
		else
			alignment[$index]="left"
		fi
		index=$((++index))
	done
}

set_column_size() {
	for ((i = 0; i < ${#input[@]}; ++i)); do
		IFS='|' read -ra row <<<"${input[$i]}"
		local index=0
		for elem in "${row[@]}"; do
			if [[ -z "$elem" ]]; then
				continue
			fi
			elem=" $(strip "${elem}") "
			if [[ -z ${column_size[$index]} || ${column_size[$index]} -lt ${#elem} ]]; then
				column_size[$index]=${#elem}
			fi
			index=$((++index))
		done
	done
}

draw_table() {
	draw_horizontal_border_line "$down_and_right" "$horizontal_and_down" "$down_and_left"

	local line_no=0
	for i in "${input[@]}"; do
		if [[ -z "$i" ]]; then
			line_no=$((++line_no))
			continue
		fi
		local index=0
		IFS='|' read -ra row <<<"$i"
		for j in "${row[@]}"; do
			j=" $(strip "$j") "
			local len=${#j}
			if [[ -z ${color} ]]; then
				header_line=true
			fi
			if [[ $line_no -eq 0 && -n ${color} ]]; then
				j="${color}${bold}$j${normal}"
			elif [[ $line_no -eq 0 && "$header_line" = true ]]; then
				j="${bold}$j${normal}"
			fi
			local align="${alignment[$index]}"
			local colsize="${column_size[$index]}"
			if ((colsize > len)); then
				if [[ -z "$align" || "$align" == "left" ]]; then
					j="$j$(printf %$((colsize - len))s)"
				elif [[ "$align" == "right" ]]; then
					j="$(printf %$((colsize - len))s)$j"
				elif [[ $(((colsize - len) % 2)) -eq 0 ]]; then
					j="$(printf %$(((colsize - len) / 2))s)$j$(printf %$(((colsize - len) / 2))s)"
				else
					j="$(printf %$(((colsize - len) / 2 - 1))s)$j$(printf %$(((colsize - len) / 2))s)"
				fi
			fi
			echo -ne "$vertical$j"
			index=$((++index))
		done
		echo -e "$vertical"

		if ((line_no < ${#input[@]} - 1)); then
			draw_horizontal_border_line "$vertical_and_right" "$vertical_and_horizontal" "$vertical_and_left"
		fi

		line_no=$((++line_no))
	done

	draw_horizontal_border_line "$up_and_right" "$horizontal_and_up" "$up_and_left"
}

draw_horizontal_border_line() {
	if (($# < 3)); then
		exit 4
	fi

	local index=0
	echo -ne "$1"
	for i in "${column_size[@]}"; do
		echo -ne "$(printf %$((i))s | sed "s/ /${horizontal}/g")"
		if ((index < ${#column_size[@]} - 1)); then
			echo -ne "$2"
		fi
		index=$((++index))
	done
	echo -e "$3"

}

strip() {
	for i in "$@"; do
		i="$(echo -e "$i" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
		echo "$i"
	done
}

parse_args "$@"
check_encoding
if [[ ${!#} == *"color:"* ]]; then
	IFS=':' read -ra c_array <<< ${!#}
	case ${c_array[1]} in
		MAGENTA) color='\033[38;5;219m'
			;;
		CYAN) color='\033[38;5;51m'
			;;
		YELLOW) color='\033[38;5;11m'
			;;
		GREEN) color='\033[38;5;10m'
			;;
		RED) color='\033[38;5;202m'
			;;
		BLUE) color='\033[38;5;27m'
			;;
	esac
	unset "file[-1]"
	unset "c_array"
fi
read_input
parse_input
draw_table