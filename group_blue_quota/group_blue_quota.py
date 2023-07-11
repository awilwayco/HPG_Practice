#!/apps/ufrc/python/3.8/bin/python

import sys
import subprocess
import argparse

# Custom action class to set a variable to True
class SetVariableAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, True)  # Set the variable to True

def parse_args(print_help=False):

    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write("error: %s\n" % message)
            self.print_help()
            sys.exit(2)

    parser = MyParser(
        usage="group_blue_quota [options]",
        description="""description: View Group's Blue Quota for HiPerGator Storage"""
    )

    parser.add_argument(
        "-v", "--version",
        action="version",
        version="""Version: {version}""".format(version="1.0.0"),
    )

    if print_help:
        parser.print_help()
        sys.exit(0)

    args = parser.parse_args()
    return args

def main():
    args=parse_args()
    print("Hello World")
    

if __name__ == "__main__":
    main()
