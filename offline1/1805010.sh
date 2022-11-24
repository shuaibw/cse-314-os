#!/usr/bin/bash

# default 100 if number of arguments is not 1
if [ $# -ne 1 ]; then
    set 100
# exit 2 if $1 is not a number
elif ! [[ $1 =~ ^[+-]?[0-9]+$ ]]; then
    echo "\$1 must be a number"
    exit 2
# exit 3 if $1 is less than 0
elif [ $1 -le 0 ]; then
    echo "\$1 must be greater than 0"
    exit 3
fi

# output csv
output=$'student_id,score\n'
# store contents of AcceptedOutput.txt in a variable
ref=$(cat AcceptedOutput.txt)


# iterate over the shell scripts in Submissions folder and run each of them
for file in Submissions/*/*.sh
do
    score=$1
    filename=$(basename "${file}")
    dirname=$(basename $(dirname "${file}"))
    # check if filename is properly named
    if ! [[ $filename =~ ^1805[0-9]{3}\.sh$ ]]; then
        echo "Invalid student id: $filename"
        score=0
        output+=$dirname,$score$'\n'
        continue
    fi
    # compare with contents of other files in the same directory
    for file2 in Submissions/*/*.sh
    do
        filename2=$(basename "${file2}")
        # skip if same file
        if [ "$filename" = "$filename2" ]; then
            continue
        fi
        # compare files
        if diff -q "$file" "$file2" > /dev/null; then
            echo "Duplicate file: $filename, penalized $((-$1))"
            score=$((-$1))
            output+=$dirname,$score$'\n'
            break
        fi
    done
    if [ $score -eq $((-$1)) ]; then
        continue
    fi
    # run the shell script and store the output in content
    content=$(bash "$file")
    # run diff on content and ref
    result=$(diff -w  <(echo "$content") <(echo "$ref"))
    # count the number of mismatched lines, ignore empty lines
    count=$(echo "$result" | grep -E -c '^(<|>)')
    # calculate score
    score=$((score - count*5))
    if [ $score -lt 0 ]; then
        score=0
    fi
    echo "File: $filename, Mismatched lines: $count, Score: $score"
    # add the score to the output
    output+=$dirname,$score$'\n'
done
# write contents to output csv
echo -n "$output" > output.csv