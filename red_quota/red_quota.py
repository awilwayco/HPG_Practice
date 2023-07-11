#!/usr/bin/env python3
"""This script will provide a formatted or machine readable (for web apps)
report on red quota usage for a specified project (group).

Author: Oleksandr Moskalenko <om@rc.ufl.edu>, 2018
"""

import sys
import argparse
import getpass
import grp
import json
from loguru import logger as log
import os
import platform
import pwd
import subprocess
import toml
from pathlib import Path

# ## CONFIG ## #
__version = "20210817"
DEBUG = False
CONFIG_FILE_PATH = "/etc/quotas.toml"
FS_NAME = "red"


def parse_args(print_help=False):
    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write("error: %s\n" % message)
            self.print_help()
            sys.exit(2)

    parser = MyParser(
        usage="%(prog)s [options] [group]",
        description="""Generate a group quota usage report for /red.
                    Specify a group or leave it out to get a report for your primary group."""
    )
    parser.add_argument(
        "--version",
        action="version",
        version="""%(prog)s
                        Version: {version}""".format(
            version=__version
        ),
    )
    parser.add_argument(
        "--rcdir",
        required=False,
        default=None,
        help=argparse.SUPPRESS
        # Main RC directory tree for configuration
    )
    entity = parser.add_mutually_exclusive_group(required=False)
    entity.add_argument(
        "-u",
        "--user",
        action="store_true",
        default=False,
        help="""show only quota use by your user. No username is required as you can only view
             your own quota use. This argument overrides '-g'/'--group'""",
    )
    parser.add_argument(
        "-g",
        "--group",
        required=False,
        default=None,
        help="show group quota use data for a group passed as an argument",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="human",
        choices=["human", "json", "csv"],
        help="output format",
    )
    parser.add_argument(
        "-l",
        "--listgroups",
        action="store_true",
        default=False,
        help="list groups",
    )
    parser.add_argument(
        "-d", "--debug", action="store_true", default=False, help=argparse.SUPPRESS
    )
    if print_help:
        parser.print_help()
        sys.exit(0)
    args = parser.parse_args()
    return args


def printe(*a):
    print(*a, file=sys.stderr)


def _get_rcdir(arg_rcdir, debug=False):
    """
    Parse rccms configuration file and return the config object.
    """
    env_rcdir = os.getenv("RCDIR", None)
    if not (arg_rcdir or env_rcdir):
        script_path = __file__
        rcdir = Path(script_path).parent.parent
    else:
        rcdir = arg_rcdir or env_rcdir
    return rcdir


def _parse_config(rcdir, debug=False):
    """
    Parse rccms configuration file and return the config object.
    """
    config_file = f"{rcdir}{CONFIG_FILE_PATH}"
    config = toml.load(config_file)
    if debug:
        log.debug(f"Config:\n{config}")
    return config


def _check_python_version(version=None):
    """
    Common utility function

    :function:`check_python_version`
        Make sure that the minimal version of python is as required.
        Checks python version and exits the run if python is too old.
        Our current minimal python3 version is 3.4.0 (from EL6 SCL).
    """
    MIN_VERSION = "3.6.0"
    import sys

    if not version:
        version = MIN_VERSION
    version_tuple = tuple([int(x) for x in version.split(".")])
    if sys.version_info < (version_tuple):
        printe("You need python {} or later to run this script.".format(version))
        return False
    return True


def _get_primary_group():
    """
    Return user's primary group.
    """
    user_data = pwd.getpwuid(os.getuid())
    primary_group = user_data.pw_gid
    group_data = grp.getgrgid(primary_group)
    group_name = group_data.gr_name
    return group_name


def _get_project_id(fs_path, group):
    """Get lustre project id from lsattr"""
    cmd = ["lsattr", "-dp", f"{fs_path}/{group}"]
    with subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True
    ) as proc:
        res_stdout = proc.stdout.read()
        res_stderr = proc.stderr.read()
        if DEBUG:
            if res_stderr:
                printe(f"ERROR: problem getting project id for {group} group")
                printe(f"ERROR: {res_stderr}")
                sys.exit(2)
                return None
        try:
            raw_data = res_stdout.strip().split("\n")[0]
            data = raw_data.strip().split()[0]
        except IndexError:
            return None
    return data


def _get_quota_use_data(fs_path, entity_type, entity_name, output_type="human"):
    """
    Generate lustre quota data
    """
    res_stdout = ""
    if entity_type == "group":
        project_id = _get_project_id(fs_path, entity_name)
        if DEBUG:
            log.debug(f"{entity_type} project id: {project_id}")
        if not project_id:
            printe(f"Group {entity_name} does not have a quota. "
                   "Go to https://www.rc.ufl.edu to make a storage investment."
                   "If you are sure you have a filesystem quota for this filesystem and the "
                   "problem persists after a few hours submit a support request at "
                   "https://support.rc.ufl.edu\n"
                   )
            sys.exit(0)
        cmd = ["lfs", "quota"]
        if output_type == "human":
            cmd.append("-h")
        else:
            cmd.append("-q")
        cmd.extend(["-p", str(project_id), fs_path])
        if DEBUG:
            log.debug(f"Quota cmd: '{' '.join(cmd)}'")
        with subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
        ) as proc:
            res_stdout = proc.stdout.read()
            res_stderr = proc.stderr.read()
        if res_stderr:
            printe(
                f"ERROR: problem getting quota for {fs_path}. Check your group list!"
            )
            print_secondary_groups()
            printe(
                "If the problem persists submit a support request at https://support.rc.ufl.edu"
            )
            printe(f"ERROR: {res_stderr}")
            sys.exit(2)
    else:
        if entity_type == "group":
            entity_argument = "-g"
        elif entity_type == "user":
            entity_argument = "-u"
        else:
            log.error("Wrong entity type, can only be user or group")
        cmd = ["lfs", "quota"]
        if output_type == "human":
            cmd.append("-h")
        else:
            cmd.append("-q")
        cmd.extend([entity_argument, entity_name])
        cmd.append(fs_path)
        if DEBUG:
            log.debug(cmd)
        with subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True
        ) as proc:
            res_stdout = proc.stdout.read()
            res_stderr = proc.stderr.read()
        if res_stderr:
            printe(
                f"ERROR: problem getting quota data for {entity_name}. Check your group list!"
            )
            print_secondary_groups()
            printe(
                "If the problem persists submit a support request at https://support.rc.ufl.edu"
            )
            printe(f"ERROR: {res_stderr}")
            sys.exit(2)
    if output_type == "human":
        raw_data = [x.strip() for x in res_stdout.strip().split("\n")[1:3]]
    else:
        raw_data = res_stdout.strip().split()
    if DEBUG:
        log.debug("Raw data: {}".format(raw_data))
    return raw_data


def format_quota_data(data, output_type):
    """
    Format quota data as json or csv
    """
    header = [
        "filesystem",
        "kbytes",
        "block_quota",
        "block_limit",
        "block_grace",
        "files",
        "file_quota",
        "file_limit",
        "file_grace",
    ]
    data_dict = dict(zip(header, data))
    if output_type == "json":
        json_data = json.JSONEncoder().encode(data_dict)
        return json_data
    elif output_type == "csv":
        csv_header = ",".join(str(x) for x in header)
        csv_data = ",".join(str(x) for x in data)
        return "\n".join([csv_header, csv_data])
    else:
        sys.exit("Unknown format type")


def print_secondary_groups():
    """
    Print a list of secondary groups.
    """
    group_names = list_secondary_groups()
    print(f"Your groups:\n\t{', '.join(group_names)}")


def list_secondary_groups():
    """
    Generate a list of secondary groups.
    """
    cmd = ["id"]
    with subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True
    ) as proc:
        res_stdout = proc.stdout.read()
    raw_data = res_stdout.split()
    data = raw_data[2].split(",")
    group_names = []
    for s in data:
        group_name = s[s.find("(") + 1: s.find(")")]
        group_names.append(group_name)
    return group_names


def _get_report_type(args, debug=False):
    """
    Check which quota report to return:
    * args.user: single user
    * args.group: single_group
    """
    admin = False
    my_username = getpass.getuser()
    if not args.group and not args.user:
        group_name = _get_primary_group()
        return "both", my_username, group_name
    if my_username == "root":
        node_name = platform.node()
        if not node_name.startswith('nosquash'):
            log.warning(
                "Root user: run on a nosquash node if get a permission denied error."
            )
        admin = True
    if args.user:
        if admin:
            return "user", args.user, ""
        else:
            if args.user != my_username:
                log.error("You cannot see another user's quota")
                sys.exit(2)
            else:
                return "user", args.user, ""
    elif args.group:
        if admin:
            return "group", "", args.group
        else:
            secondary_groups = list_secondary_groups()
            if args.group not in secondary_groups:
                log.error("You can only view quotas for your groups.")
                print_secondary_groups()
                sys.exit(2)
            return "group", "", args.group


def main():
    """
    Produce a group quota usage report for red filesystem.
    """
    _check_python_version()
    args = parse_args()
    if args.debug:
        global DEBUG
        DEBUG = True
        print("Debugging enabled")
    rcdir = _get_rcdir(args.rcdir, DEBUG)
    config = _parse_config(rcdir, DEBUG)
    if args.listgroups:
        print_secondary_groups()
        sys.exit(0)
    report_type, username, groupname = _get_report_type(args)
    if DEBUG:
        log.debug(f"Report for {report_type}, user: {username}, group: {groupname}")
    fs_path = config[FS_NAME]["path"]
    fs_name = FS_NAME.capitalize()
    # /lustre/red
    if args.output == "human":
        if report_type in ["both", "group"]:
            print()
            quota_data = _get_quota_use_data(
                fs_path, "group", groupname, output_type="human"
            )
            quota_data[1] = "     " + quota_data[1].replace(fs_path, fs_name)
            quota_data.insert(
                0, f"Disk quota for '{groupname}' group on {FS_NAME.capitalize()} filesystem"
            )
            print("\n".join(quota_data))
        if report_type in ["both", "user"]:
            print()
            quota_data = _get_quota_use_data(
                fs_path, "user", username, output_type="human"
            )
            quota_data.insert(
                0, f"Disk quota for user '{username}' on {fs_name} filesystem"
            )
            quota_data[1] = quota_data[1].strip()
            quota_data[2] = "     " + quota_data[2].replace(fs_path, fs_name)
            print("\n".join(quota_data))
            print(
                "\nNote: you do not have permission to view data for other users in your group."
            )
        print("\nSee additional options with 'red_quota -h'")
    else:
        if args.user:
            my_username = getpass.getuser()
            entity_name = my_username
            entity_type = "user"
        else:
            entity_name = groupname
            entity_type = "group"
        quota_data = _get_quota_use_data(
            fs_path, entity_type, entity_name, output_type=args.output
        )
        formatted_quota_data = format_quota_data(quota_data, args.output)
        print(formatted_quota_data)


if __name__ == "__main__":
    main()
