#!/usr/bin/env bash

ESC=$(printf '\033')
strsplit() {
	cut -d $1 -f $3 <<< $2
}
mod() {
	printf $(((($1 % $2) + $2) % $2))
}


BLINKING=1
blinking_set() {
	case $1 in
		0) printf "$ESC[?25l"; BLINKING=0;;
		*) printf "$ESC[?25h"; BLINKING=1;;
	esac
}


cursor_set() {
	local row=$(($1 + 1))
	local col=$(($2 + 1))
	printf "$ESC[$row;${col}H"
}
cursor_get() {
	printf "$ESC[6n" > /dev/tty
	local line
	read -s -d R line < /dev/tty
	line="${line#*[}"
	ROW=$(($(strsplit ';' $line 1) - 1))
	COL=$(($(strsplit ';' $line 2) - 1))
}


input_key() {
	read -r -s -n1 key # 2>/dev/null >&2
	if [[ $key = $ESC ]]; then
		read -r -s -n1 key # 2>/dev/null >&2
		if [[ $key = [ ]]; then
			read -r -s -n1 key # 2>/dev/null >&2
			case $key in
				A) echo up;;
				B) echo down;;
				C) echo right;;
				D) echo left;;
			esac
		fi
	fi
	case $key in
		"") echo enter;;
	esac
}
_select_option() {
	local oldstty=$(stty -g)
	trap "stty $oldstty; blinking_set 1" 2
	echo $1
	shift
	for opt; do printf "\n"; done
	cursor_get
	local lastrow=$ROW
	local startrow=$(($lastrow - $#))
	blinking_set 0
	local selected=0
	while true; do
		local i=0
		for opt; do
			cursor_set $(($startrow + $i)) 0
			if [ $i -eq $selected ]; then
				printf "  $ESC[7m $opt $ESC[27m";
			else
				printf "   $opt ";
			fi
			((i++))
		done
		case $(input_key) in
			enter) break;;
			up) selected=$(mod $((selected - 1)) $#);;
			down) selected=$(mod $((selected + 1)) $#);;
		esac
	done
	stty $oldstty; blinking_set 1; printf '\n\n'
	return $selected
}
select_option() {
	_select_option "$@" 1>&2
	echo $?
}


case $(select_option "Choose a thing:" "one" "two" "three") in
	0) echo "You chose one!";;
	1) echo "You chose two!";;
	2) echo "You chose three!";;
esac
