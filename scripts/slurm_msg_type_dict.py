#! /usr/bin/env python3
"""
Parse $slurmrepo/src/common/slurm_protocol_defs.h and create
a small C program that generates a mapping of the numeric
slurm msg types to their symbolic names.

Example:
    ./slurm_msg_type_dict.py $slurmrepo/src/common/slurm_protocol_defs.h > msgdict.c
    gcc -o msgdict msgdict.c
    ./msgdict
"""

import re
import sys
import argparse

def generate_c(header_file_name):
    typedef_re = re.compile(r"\s*typedef\s+enum\s*{(.*?)}\s*slurm_msg_type_t\s*;", re.DOTALL)
    symbol_re = re.compile(r"^\s*([A-Z0-9_]+)\s*[,=\n]")

    with open(header_file_name, mode="r", encoding="utf-8") as header_file:
        header = header_file.read()
    typedef = typedef_re.search(header)
    if typedef is None:
        print("could not identify the slurm_msg_type_t typedef in the header file")
        sys.exit(1)

    print("""#include <stdio.h>""")
    print(typedef.group(0))
    print("""\n\nint main(void) {""")
    for line in typedef.group(1).split("\n"):
        symbol = symbol_re.match(line)
        if symbol is not None:
            print(f"""    printf("%d: \\\"%s\\\",\\n", {symbol.group(1)}, "{symbol.group(1)}");""")
        else:
            print(f"""    printf("\\n");""")
    print("""    return 0;\n}""")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("header", help="$slurmrepo/src/common/slurm_protocol_defs.h")
    args = parser.parse_args()
    generate_c(args.header)

if __name__ == "__main__":
    main()
