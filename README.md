# Citation-Manager
Helps to manage manually placed citations from a document checking them against the provided bibliography - poor man's bibtex!



# Citations Processing Script

This `citations` script provides functionalities to extract, verify, and manage citation keys and references within a text file. The script is designed to help users maintain consistent citation formatting by identifying and matching all referenced citation keys with corresponding entries in a bibliography.

## Features
1. **Extract Citation Keys**: Extract unique citation keys from a text file and store them in a specified key file.
2. **Citation Verification**: Check whether each citation key in the key file has a corresponding entry in the references file, ensuring consistency between cited references and bibliography entries.
3. **Error and Warning Handling**: Detect and report any ill-formed citation keys, missing references, or unmatched brackets.

## Requirements
- **Bash 4.4** (or higher)
- **Tested Environment**: The script has been tested on **Windows Subsystem for Linux (WSL)** using **Bash 4.4**.

## Usage

Run the script with the following options:

```bash
citations [options]
```

### Options

- **`-k, --key <file>`**  
  Specify the reference keys file.  
  Default: `reference-keys.txt`

- **`-r, --references <file>`**  
  Specify the references file.  
  Default: `references.txt`

- **`-ns, --NoStatus`**  
  Suppress status messages.

- **`-t, --text <file>`**  
  Specify a text file to extract unique reference keys.

- **`-nw, --NoWarning`**  
  Suppress warning messages.

- **`-er, --ExtractReferences`**  
  Extract references from the specified text file (requires the `-t` or `--text` option).

- **`-h, --help`**  
  Display the help message and exit.

## Examples

1. **Extract Citation Keys**
   ```bash
   citations -t EssayText.txt -er
   ```
   Extracts unique citation keys from `EssayText.txt` and stores them in the default key file (`reference-keys.txt`).

2. **Check Citations for Consistency**
   ```bash
   citations -k my_keys.txt -r my_references.txt
   ```
   Checks that every citation key in `my_keys.txt` has a corresponding entry in `my_references.txt` and vice versa.

3. **Suppress Status and Warning Messages**
   ```bash
   citations -ns -nw
   ```

## Script Details

### Citation Extraction and Verification

The script offers two primary functions:

1. **Extract Keys**: 
   Use this function to extract citation keys from a text file, store them in `reference-keys.txt`, and identify any ill-formed citation keys. Activate this feature with `-er` (requires a text file specified with `-t`).

2. **Citation Checking**: 
   Use this function to check if every citation key in the key file has an entry in the references file, and if every entry in the references file is cited in the text. This is the default functionality of the script when provided with `reference-keys.txt` and `references.txt`.

### Expected File Formats

- **Key File (reference-keys.txt)**:  
  Contains a list of citation keys, one per line.
  ```
  [AB+12]
  [J05]
  ```

- **References File (references.txt)**:  
  Contains a list of citation key references, one per line, with each reference formatted as a key and its corresponding citation details.
  ```
  [AB+12] John Doe. Title of the Reference. ...
  ```

## Error Handling

The script performs several checks to ensure the validity of citation keys and references:
- Warns about ill-formed references, missing references, and unmatched brackets.
- Verifies that the script has read and write permissions for specified files.

## Exit Codes
- `0` on successful completion.
- Non-zero exit code if errors occur (e.g., missing files, ill-formed citations).

## Notes

- **Compatibility**: The script is tested and verified to work on WSL (Windows Subsystem for Linux) with Bash 4.4.
- **Bash Version**: Some commands and syntax used may require Bash 4.4 or newer.

## License

This script is licensed under the Apache 2.0 License

---

For questions or issues, please contact the developer or submit an issue on the GitHub repository.
