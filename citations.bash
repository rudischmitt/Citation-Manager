#!/bin/bash
set -e


# ToDo:
#   - test cases
#   - make sure various combinations of command line arguments work
#   - improve ouput of meesages and possibly control
#   - output references processed into a log file; similar for ill-formed ones


# Enable both tracing and verbose modes
# set -xv

key_file="reference-keys.txt"
ref_file="references.txt"
wrapped_file="wrapped_text.txt"
extract_references=false
show_status=true
show_warnings=true
text_file=""


# Function to check if a file exists and is not empty
check_file() {
    local file="$1"
    local description="$2"
    if [ ! -f "$file" ]; then
        echo "Error: $description file $file does not exist. Please provide a valid file."
        exit 1
    fi
    if [ ! -s "$file" ]; then
        echo "Error: $description file $file is empty. Please provide a valid file with entries."
        exit 1
    fi
}

# Function to announce status messages
announce_status() {
    if [ "$show_status" = true ]; then
        echo -e "\e[32mStatus: '$1'\e[0m"
    fi
}

# Function to warn about issues on stderr
warn() {
    local message="$1"
    # Print colored warning only to the terminal, but use plain text for processing
    echo -e "\e[31mWarning: $message\e[0m" >&2
}

# Function to warn about issues on stdout
warn_stdout() {
    if [ "$show_warnings" = true ]; then
        echo -e "\e[31mWarning: $1\e[0m"
    fi
}

# Function to check if the script has read/write permissions for a file
check_permissions() {
    local file="$1"
    local description="$2"
    if [ ! -r "$file" ]; then
        echo "Error: Cannot read from $description file $file. Check file permissions."
        exit 1
    fi
    if [ ! -w "$file" ]; then
        echo "Error: Cannot write to $description file $file. Check file permissions."
        exit 1
    fi
}

#
# Start of citations processing script
# 


# Command line argument processing
while [[ $# -gt 0 ]]; do
    case $1 in
        -nw|--NoWarning)
            show_warnings=false
            shift # past argument
            ;;
        -k|--key)
            key_file="$2"
            shift # past argument
            shift # past value
            ;;
        -r|--references)
            ref_file="$2"
            shift # past argument
            shift # past value
            ;;
        -ns|--NoStatus)
            show_status=false
            shift # past argument
            ;;
        -t|--text)
            text_file="$2"
            shift # past argument
            shift # past value
            ;;
        -er|--ExtractReferences)
            extract_references=true
            shift # past argument
            ;;
        -h|--help)
            echo "Usage: citations [options]

Script provides two primary citations processing functions:

(1) Extract Keys: Use to extract citation keys from a text file (e.g., a paper), store them in reference_keys.txt and check whether the text contains any ill-formed citation keys and show them. Use the -er (--ExtractReferences) options (it requires a text to process as input (-t (--Text)).

(2) Citation Checking: Use to check whether every citation key in reference_keys.txt has a corresponding entry in references.txt. That is, do all our citation keys have entries in our reference section (i.e., in our bibliography). Output any citation keys that don't have corresponding referneces; also, output any references in references.txt that have no corresponding citation key in reference_keys.txt, i.e., are not cited in our text. 

Citation Checking is the default functionality of our script; it assumes a file with keys (reference_keys.txt) and a file with references (references.txt).

The file reference_keys.txt contains a list of citation keys (one per line).
  Example:
     [AB+12]
     [J05]
     ...

The file references.txt contains a list of citation key references (one per line).
  Example:
     [AB+12]	 John Doe. Title ... .
     ...

Both files can be provided as input (-k/--key and -r/--references).


Options:
  -k, --key <file>         Specify the reference keys file (default: reference-keys.txt)
  -r, --references <file>  Specify the references file (default: references.txt)
  -ns, --NoStatus          Do not output status messages
  -t, --text <file>        Specify a text file to extract unique reference keys
  -nw, --NoWarning         Suppress warning messages
  -er, --ExtractReferences Extract references from the provided text file
  -h, --help               Show this help message and exit"
            exit
            ;;
        *)
            echo "Error: Unknown option: $1"
            exit 1
            ;;
    esac
done

# Extract references from text and check whether there are ill-formed references in text
# Check Dependencies for `-er`: Ensure `-t` is provided when `-er` is used
if [ "$extract_references" = true ]; then
    if [ -z "$text_file" ]; then
        echo "Error: -er (--ExtractReferences) requires -t (--text) to be provided. Please provide a text file to extract references from."
        exit 1
    else
	# If ExtractReferences is true and text_file is provided, extract
	# unique reference keys and store them in key_file
	# check_file et al. below is redundant
	check_file "$text_file" "Text"
	check_permissions "$text_file" "Text"

	# Extract well-formed references 
	if [ -f "$key_file" ]; then
            warn "Key file '$key_file' already exists."
            read -r -p "Do you want to overwrite it? (y/n): " choice
            if [[ "$choice" != "y" ]]; then
		announce_status "Exiting without overwriting the key file."
		exit 1
            fi
	fi
	announce_status "Extracting unique reference keys from '$text_file' and storing in '$key_file'..."
	grep -o -E "\[[A-Za-z0-9+ ]+\]" "$text_file" | sort | uniq > "$key_file"
	extracted_count=$(wc -l < "$key_file")

	# Check for ill-formed references in text_file
	announce_status "Checking for ill-formed references in '$text_file'..."
	ill_formed_count=0

	# Pre-process the text file to wrap long lines (use a temporary file)
	fold -s -w 80 "$text_file" > "$wrapped_file"
	# Read each line from the text file
	
	# Ensure `wrapped_file` exists and is formatted correctly before entering the loop
	if [ -f "$wrapped_file" ]; then
	    while IFS= read -r line || [[ -n "$line" ]]; do			    
		# ToDo: Could skip processing if line is empty
		# !!! Use `|| true` to prevent `set -e` from exiting if no matches are found
		matches=$(grep -o -E '\[.*?\]|\[|\]' <<< "$line" || true)

		# If matches array is empty, skip to the next line
		if [[ -z "$matches" ]]; then
		    continue
		fi
		
		for match in $matches; do
		    # Check for valid keys in format `[...]+`
		    # ToDo: Could merge with above extraction of well-formed references
		    if [[ "$match" =~ ^\[([A-Za-z0-9+ ]*)\]$ ]]; then
			continue
		    fi

		    # Check for isolated brackets
		    if [[ "$match" == "[" ]] || [[ "$match" == "]" ]]; then
			warn "Unmatched bracket found in '$text_file': $line"
			((ill_formed_count++))
			continue
		    fi

		    # Check for empty or whitespace-only brackets
		    if [[ "$match" =~ ^\[\s*\]$ ]]; then
			warn "Empty or whitespace-only reference found in '$text_file': $match"
			((ill_formed_count++))
			continue
		    fi

		    # Any other case is considered an ill-formed reference
		    warn "Ill-formed reference found in '$text_file': $match"
		    ((ill_formed_count++))
		done
	    done < "$wrapped_file"
	    announce_status "$extracted_count unique references have been extracted from '$text_file' and stored in '$key_file'."
	    announce_status "$ill_formed_count ill-formed references found in '$text_file'."
            rm "$wrapped_file"
	else
	    echo "Error: Wrapped file '$wrapped_file' does not exist. Exiting."
	    exit 1
	fi
    fi
    # Only --ExtractReferences was called for; exit
    exit 1
fi

# Ensure ref_file exists and is not empty
check_file "$ref_file" "References"
check_permissions "$ref_file" "References"

# Here, could check whether reference file is properly formatted
# Announce start of reference format check in ref_file
# announce_status "Checking references in $ref_file for correct format..."

# Ensure key_file exists and is not empty
check_file "$key_file" "Key"
check_permissions "$key_file" "Key"

# Announce start of key_file processing
announce_status "Processing reference keys in '$key_file' and matching with references in '$ref_file'..."

# Track used keys
declare -A key_usage

# Process key_file for extracting references
while IFS= read -r line
do
    # Our key string should technically look like "[...]", otherwise ignore.
    if [[ ${line:0:1} != "[" ]] || [[ ${line: -1} != "]" ]]; then
        warn "Not in correct citation format ([...])! Ignoring: $line"
        continue
    fi
    # Extract the full references based on the key from references.txt
    # -F means Fixed String, literal interpretation of $line, does not
    # interprete content of $line as a regex
    reference=$(grep -F "$line" "$ref_file")
    # Below only removes TRAILING whitespace using bash substitution
    # ${variable//pattern/replacement}
    refClean="${reference// *$/}"
    if [ -z "$refClean" ]; then
        warn "Citation key $line not found in '$ref_file'"
    else    
        echo "$refClean"
        key_usage["$line"]=1
    fi
done < "$key_file"

# Check for unused keys
unused_keys=false
while IFS= read -r line
do
    if [[ ${line:0:1} == "[" ]] && [[ ${line: -1} == "]" ]]; then
        if [ -z "${key_usage[$line]}" ]; then
            warn "Citation key $line in '$key_file' has no entry in '$ref_file'"
            unused_keys=true
        fi
    fi
done < "$key_file"

# Announce all keys used if no unused keys found
if [ "$unused_keys" = false ]; then
    announce_status "All keys in '$key_file' have corresponding entries in '$ref_file'."
fi

# This is not going to work; we need to isolate the reference keys in ref_file
# Check for references in ref_file that have no corresponding key
unused_references=false
processed_any_reference=false

while IFS= read -r line
do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Remove leading whitespace using parameter substitution
    line="${line#"${line%%[![:space:]]*}"}"

    # Simpler pattern does not work
    # line="${line##*( )}"
    
    # Extract key (first part of the line) using parameter substitution
    key="${line%% *}"
     
    # Sanity check to ensure key starts with '[' and ends with '}'
    if [[ ${key:0:1} != "[" ]] || [[ ${key: -1} != "]" ]]; then
        warn "Skipping line due to improperly formatted key: $key"
        continue
    fi
        
    processed_any_reference=true
    if [ -z "${key_usage[$key]}" ]; then
        warn "Reference $key in '$ref_file' has no corresponding key in '$key_file'"
        unused_references=true
    fi
done < "$ref_file"

# Announce all references have corresponding keys if no unused references found
if [ "$unused_references" = false ] && [ "$processed_any_reference" = true ]; then
    announce_status "All references in '$ref_file' have corresponding keys in '$key_file'."
elif [ "$unused_references" = false ] && [ "$processed_any_reference" = false ]; then
    announce_status "No references from '$ref_file' have corresponding keys in '$key_file'!!!"
fi


# Disable tracing and verbose modes
# set +xv
