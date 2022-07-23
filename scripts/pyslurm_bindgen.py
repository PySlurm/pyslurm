#!/usr/bin/env python3

import autopxd
import click
import os
import re
import pathlib
from collections import OrderedDict

UINT8_RANGE = range((2**8))
UINT16_RANGE = range((2**16))
UINT32_RANGE = range((2**32))
UINT64_RANGE = range((2**64))
INT8_RANGE = range(-128, 127+1)

# TODO: also translate slurm enums automatically as variables like:
# <ENUM-NAME> = slurm.<ENUM_NAME>

def get_data_type(val):
    if val in UINT8_RANGE:
        return "uint8_t"
    elif val in UINT16_RANGE:
        return "uint16_t"
    elif val in UINT32_RANGE:
        return "uint32_t"
    elif val in UINT64_RANGE:
        return "uint64_t"
    elif val in INT8_RANGE:
        return "int8_t"
    else:
        raise ValueError("Cannot get data type for value: {}".format(val))


def try_get_macro_value(s):
    if s.startswith("SLURM_BIT"):
        val = int(s[s.find("(")+1:s.find(")")])
        return 1 << val

    if s.startswith("0x"):
        return int(s, 16)

    if s.startswith("(0x"):
        _s = s[s.find("(")+1:s.find(")")]
        return int(_s, 16)

    try:
        return int(s)
    except ValueError:
        pass

    return None


def translate_slurm_header(hdr_dir, hdr):
    hdr_path = os.path.join(hdr_dir, hdr)

    with open(hdr_path) as f:
        translate_hdr_macros(f.readlines(), hdr)

        c = click.get_current_context()
        if c.params["show_unparsed_macros"] or c.params["generate_python_const"]:
            return

        codegen = autopxd.AutoPxd("slurm/" + hdr)
        codegen.visit(
            autopxd.parse(
                f.read(),
                extra_cpp_args=[hdr_path],
                whitelist=[hdr_path],
            )
        )

        print(str(codegen))


def handle_special_cases(name, hdr):
    if hdr == "slurm.h":
        if name == "PARTITION_DOWN":
            return "uint8_t"
        elif name == "PARTITION_UP":
            return "uint8_t"
        elif name == "PARTITION_DRAIN":
            return "uint8_t"

    return None


def parse_macro(s, hdr):
    vals = " ".join(s.split()).split()
    if not len(vals) >= 3:
        return None, None

    name = vals[1]
    val = vals[2]

    v = try_get_macro_value(val)

    if v is None:
        v = handle_special_cases(name, hdr)
        return name, v

    return name, get_data_type(v)


def translate_hdr_macros(s, hdr):
    vals = OrderedDict()
    unknown = []
    for line in s:
        if line.startswith("#define"):
            name, ty = parse_macro(line.rstrip('\n'), hdr)
            if ty:
                vals.update({name: ty})
            elif name and not ty:
                unknown.append(name)

    c = click.get_current_context()
    if c.params["show_unparsed_macros"]:
        if unknown:
            print("Unknown Macros in {}: \n".format(hdr))
            for u in unknown:
                print(u)
            print("")
        return

    if vals:
        if c.params["generate_python_const"]:
            for name, ty in vals.items():
                print("{} = slurm.{}".format(name, name))
        else:
            print("cdef extern from \"{}\":".format("slurm/" + hdr))
            print("")
            for name, ty in vals.items():
                print("    {} {}".format(ty, name))
            print("")


def setup_include_path(hdr_dir):
    include_dir = pathlib.Path(hdr_dir).parent.as_posix()
    if not os.environ.get("C_INCLUDE_PATH", None):
        os.environ["C_INCLUDE_PATH"] = include_dir


@click.command(
    context_settings=dict(help_option_names=["-h", "--help"]),
    help="Generate Slurm API as Cython pxd file from C Headers.",
)
@click.option(
    "--slurm-header-dir",
    "-D",
    metavar="<dir>",
    help="Directory where the Slurm header files are located.",
)
@click.option(
    "--show-unparsed-macros",
    "-u",
    default=False,
    is_flag=True,
    help="Show only names of macros that cannot be translated and exit.",
)
@click.option(
    "--generate-python-const",
    "-c",
    default=False,
    is_flag=True,
    help="Generate variables acting as constants from Slurm macros.",
)
def main(slurm_header_dir, show_unparsed_macros, generate_python_const):
    setup_include_path(slurm_header_dir)
    translate_slurm_header(slurm_header_dir, "slurm_errno.h")
    translate_slurm_header(slurm_header_dir, "slurm.h")
    translate_slurm_header(slurm_header_dir, "slurmdb.h")


if __name__ == '__main__':
    main()
