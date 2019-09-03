import sys
import cli_script_example

def add_subparsers(original_parser):
    """ ADVANCED USE CASE: Subparsers
    One could make use of subparsers when the script does more than one main
    thing (i.e. similar to git commands init, status, add, etc. subparsers)
    """

    arg_subparsers = original_parser.add_subparsers(
        dest='subp',
        help='Subparser Help')

    arg_subparser1 = \
        arg_subparsers.add_parser(
            'subcommand1',
            help="Call subcommand 1"
        )

    arg_subparser2 = \
        arg_subparsers.add_parser(
            'subcommand2',
            help="Call subcommand 2"
        )

    arg_subparser2.add_argument(
        '-l',
        action='append',
        metavar="ARG",
        dest='arglist',
        help='A list of argument, -l should be preprended each time the '
             'argument is repeated, like "-l val1 -l val2"'
    )

    # A default function call can be associated with a subparser
    arg_subparser1.set_defaults(call_func=subparser1_default_function)
    return original_parser


def subparser1_default_function(f_kwargs):
    print(" --- THIS IS THE DEFAULT FUNCTION CALL ---")
    cli_script_example.print_dict(script_kwargs, "function kwargs")


def subparser_function_call(f_func, f_kwargs):
    try:
        print(" --- Trying call to default function (function={}) ---"
              .format(f_func))
        f_func(f_kwargs)
    except TypeError as nonetype_func:
        print(" --- No default function associated with {subparser} ---"
              .format(subparser=f_kwargs['subp']))
        print(" --- Call to {subp} default ".format(subp=f_kwargs['subp']) +
              "function {f_func} was a failure ---".format(f_func=f_func))
    else:
        print(" --- Call to {subp} default ".format(subp=f_kwargs['subp']) +
              "function {f_func} was a success ---".format(f_func=f_func))



if __name__ == "__main__":
    script_parser = cli_script_example.init_parser()
    script_parser = add_subparsers(script_parser)
    if (len(sys.argv) < 1):  # User did not provide any argument
        script_parser.parse_args(['-h'])  # Help that guy!

    script_args = script_parser.parse_args(sys.argv[1:])
    # script_args is a 'Namespace'
    # make script_args a dictionary
    script_kwargs = vars(script_args)

    if script_kwargs.get('subp', None) is not None:
        # retrieve default function in kwargs (it's the 'call_func' key)
        f_func = script_kwargs.get('call_func', None)
        # default will be None if it was not not set
        subparser_function_call(f_func, script_kwargs)
    else:
        print(" --- No subparser, calling cli_script_example.main() --- ")
        cli_script_example.main(script_kwargs)


