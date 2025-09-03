import sys


def modify_file(filename):
    with open(filename, "r") as file:
        lines = file.readlines()

    # Filter out empty lines
    non_empty_lines = [line for line in lines if line.strip()]

    # If there are not enough non-empty lines, handle the error
    if len(non_empty_lines) < 2:
        print("File doesn't contain enough lines to modify.")
        return

    # Find the index of the second-to-last non-empty line and the last one
    second_last_index = len(non_empty_lines) - 2
    last_index = len(non_empty_lines) - 1

    # Add a comma to the second-to-last non-empty line
    non_empty_lines[second_last_index] = (
        non_empty_lines[second_last_index].strip() + ",\n"
    )

    # Insert the new line before the last non-empty line
    non_empty_lines.insert(
        last_index,
        '{"name":"Cheat_Menu","status":true,"description":"","parameters":{}}\n];\n',
    )

    # Replace the non-empty lines back into the original lines
    modified_lines = []
    non_empty_count = 0
    for line in lines:
        if line.strip():
            modified_lines.append(non_empty_lines[non_empty_count])
            non_empty_count += 1
        else:
            modified_lines.append(line)

    # Write the modified lines back to the file
    with open(filename, "w") as file:
        file.writelines(modified_lines)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <filename>")
        sys.exit(1)

    input_filename = sys.argv[1]
    modify_file(input_filename)
