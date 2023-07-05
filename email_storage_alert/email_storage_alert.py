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
        usage="email_storage_alert [options] [group]",
        description="""description: Email Alert Service for HiPerGator Storage"""
    )

    parser.add_argument(
        "-v", "--version",
        action="version",
        version="""Version: {version}""".format(version="1.0.0"),
    )

    parser.add_argument('-s', '--send', action="store_true", help='Enable send flag')

    if print_help:
        parser.print_help()
        sys.exit(0)

    args = parser.parse_args()
    return args
    
def main():
    args=parse_args()
    if args.send:
        subprocess.call(['bash', 'email_script.sh', '-s'])
    else:
        subprocess.call(['bash', 'email_script.sh'])

if __name__ == "__main__":
    main()