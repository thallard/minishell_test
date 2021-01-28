# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    test.sh                                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: thallard <thallard@student.42lyon.fr>      +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2021/01/13 20:16:23 by thallard          #+#    #+#              #
#    Updated: 2021/01/28 15:09:34 by thallard         ###   ########lyon.fr    #
#                                                                              #
# **************************************************************************** #

GREEN='\033[0;32m'
RED='\033[0;31m'
REDB='\033[1;31m'
BLANK='\033[0m'
YELLOW='\033[0;33m'

# ----------------------- MODIFY THESE VARIABLES ----------------------------
# Please modify this variable if your Makefile or your minishell executable is not found
PATH_Makefile=..
PATH_executable=./minishell

# Variables
i=1
FILE_TO_READ=
RUN=1
DIFF_FLAGS=0
ALL=0
SPEED=0.09
VALGRIND=

# Check if 0 arguments is set 
if [ "$1" == "help" ]; then
    printf "How to use this tester ?\n"
    printf "    use ${YELLOW}\"bash test.sh [--diff] [--fast] [--valgrind] <name_file> ...\"${BLANK} to run a specific built-in command test (echo, unset, export, etc...).\n"
	printf "    use ${YELLOW}\"bash test.sh all\"${BLANK} to run all commands test at the same time.\n\n"
    printf "    flag ${YELLOW}[--diff]${BLANK} allow when its enabled to see the difference(s) between your minishell results and real bash ones, without this flag enabled you will only see if the test is correct.\n"
	printf "    flag ${YELLOW}[--fast] ${BLANK}or ${YELLOW}[-f] ${BLANK}allow to increase the delay between each test.\n"
	printf "    flag ${YELLOW}[--valgrind] ${BLANK}or ${YELLOW}[-v] ${BLANK} enable leaks checking (Valgrind works only on Linux OS, see the repository of gurival- : https://github.com/grouville/valgrind_42, it's an effiency tool which allow to use Valgrind on your minishell easily.\n"

    exit
fi

# Check if Makefile and minishell executable exists in the parent folder
if [[ -f "$PATH_Makefile/Makefile" ]]; then
	make all -C ..
else
	printf "\033[1;31mError : Makefile doesn't found with the path : \"$PATH_Makefile\", please be sure to change the variable \"PATH_Makefile\" or to move your Makefile in the right folder.\n"
	RUN=0
fi
if [[ -f "$PATH_executable" ]]; then
	cp ../minishell . 
else
	printf "\033[1;31mError : Executable \"minishell\" doesn't found with the path : \""$PATH_executable"\", please be sure to change the variable \"PATH_executable\" or to move your executable in the right folder.\n"
	RUN=0
fi

# Run main program if all the checks are done
if [ "$RUN" == "1" ]; then
	# Read inputs files for cat command
	if [ -z "$1" ]; then
		printf "\033[1;32mYou choose to run all tests without ${YELLOW}[--diff]\033[1;32m (differences between minishell and bash results).${BLANK}\n\n"
		FILE_TO_READ="$(find file_tests -type f -name "*.txt" -print)"
		ALL=1
		sleep 4
	else
		for var in "$@"
		do
			if [ "$var" == "--diff" ]; then
				printf "\033[1;32mYou choose to run all tests.${BLANK}\n\n"
				FILE_TO_READ="$(find file_tests -type f -name "*.txt" -print)"
				DIFF_FLAGS=1
			elif [ "$var" == "--fast" ] || [ "$var" == "-f" ]; then
				printf "oui"
				SPEED=0.001
			elif [ "$var" == "--valgrind" ] || [ "$var" == "-v" ]; then
				VALGRIND="valgrind -q --leak-check=full"
			else
				if [ "$var" == "all" ]; then
					FILE_TO_READ="$(find file_tests -type f -name "*.txt" -print)"
					if [ -z "$(find file_tests -type f -name "*.txt" -print)" ]; then
						printf "${REDB}Error, 0 files founded in ./file_tests with \"all\" tag.\n"
						exit
					fi
					ALL=1
					break 
				else
					FILE_TO_READ="$FILE_TO_READ $(find file_tests -name "$var?*" -print)"
					if [ -z "$(find file_tests -name "$var?*" -print)" ]; then
						printf "${REDB}Error, 0 files founded with \"${var}\" tag.\n"
						exit
					fi
				fi
			fi
		done
	fi
	# Added all files if 0 files name or "all" is specified
	if [ "$ALL" == "0" ] && [ -z "$FILE_TO_READ" ]; then
		FILE_TO_READ="$(find file_tests -type f -name "*.txt" -print)"
		if [ -z "$(find file_tests -type f -name "*.txt" -print)" ]; then
			printf "${REDB}Error, 0 files founded in ./file_tests with \"all\" tag.\n"
			exit
		fi
		ALL=1
	fi
	echo -n > tofix/tofix_tests.txt
	echo -n > tmp/tmp
	# Main process checking each line and compare minishell executable + bash results
	cat $FILE_TO_READ | while read line
		do
			if [ "$line" == "\n" ]; then
				continue
			fi
			# If Valgrind flags is enabled, run tests with valgrind
			BASH_RESULT=$(echo $line | bash 2>&-)
			BASH_EXIT=$?
			MINISHELL_RESULT=$(echo $line | $VALGRIND ./minishell 2>&-)
			MINISHELL_EXIT=$?
			if [ "$DIFF_FLAGS" == "1" ]; then
				if [ "$BASH_RESULT" == "$MINISHELL_RESULT" ] && [ "$BASH_EXIT" == "$MINISHELL_EXIT" ]; then
						printf "${GREEN}$i: $line\n"
						echo $line >> tmp/tmp
				else
					if [ "$BASH_EXIT" == "$MINISHELL_EXIT" ]; then
						printf "${RED}$i:        [$line]\nbash     : [$BASH_RESULT]${GREEN}[$BASH_EXIT]${RED}\nminishell: [$MINISHELL_RESULT]${GREEN}[$MINISHELL_EXIT]\n"
						echo $line >> tofix/tofix_tests.txt
					else
						printf "${RED}$i:        [$line]\nbash     : [$BASH_RESULT][$BASH_EXIT]\nminishell: [$MINISHELL_RESULT][$MINISHELL_EXIT]\n"
						echo $line >> tofix/tofix_tests.txt
					fi
				fi
			else
				if [ "$BASH_RESULT" == "$MINISHELL_RESULT" ] && [ "$BASH_EXIT" == "$MINISHELL_EXIT" ]; then
					printf "${GREEN}$i: [$line]\n"
					echo $line >> tmp/tmp
				else
					printf "${RED}$i: [$line]\n"
					echo $line >> tofix/tofix_tests.txt
				fi
			fi
			i=$((i + 1))
			sleep $SPEED
		done
		printf "\n${GREEN}Conclusion : $(cat tmp/tmp | wc -l | xargs)/$(cat $FILE_TO_READ | wc -l | xargs) tests passed.\n"
		printf "$(cat tofix/tofix_tests.txt | wc -l | xargs) wrong tests were added in \"${YELLOW}./tofix/tofix_tests.txt${GREEN}\".\n"
		rm -rf tmp/tmp
fi
rm -f a bar file foo je lol ls suis 'test' teststicked testyosticked