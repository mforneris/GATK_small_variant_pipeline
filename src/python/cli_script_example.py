#!/usr/bin/env python3
# Use python3. See https://pythonclock.org/

# import libraries
import os
import sys
import argparse # should be part of stdlib since 2.7

try:
    import ruamel.yaml as yaml
except ImportError as yaml_imp_err:
    yaml_imp_err_msg = """
######################################################
Failed importing the needed yaml library (ruamel.yaml)
Run "pip install ruamel.yaml"
See https://pypi.python.org/pypi/ruamel.yaml
###################################################### """
    sys.exit(yaml_imp_err_msg)

# utils functions
def print_dict(dictionary, name ="dictionary"):
    dict_dump = yaml.dump(dictionary, default_flow_style=False)
    dashes = "".join([ "-" for l in name ])
    print("\n{name}\n{dashes}\n{ddump}"
          .format(name=name,
                  dashes=dashes,
                  ddump=dict_dump))


def get_yaml():
    """ Get a yaml config file at ../../config/config.yml

    A better solution would be to give the yaml file as a command line
    argument and resolve the path using
    os.path.normpath(os.path.join(os.getcwd(), path))
    """
    yaml_file_path = \
        os.path.normpath(  # normalises ../..
            os.path.join(
                os.path.dirname(__file__),  # this script path
                "../../config/config.yml"
            )
        )
    return yaml_file_path



def import_yaml_config_as_dict(yaml_file_path):
    """ Reads a YAML file located at *yaml_file_path* and returns
     a typical python dictionary

    Note, the script WILL NOT fail if an error occurs while reading the
    YAML file, instead this will print the exception and return an empty
    dictionary
    """
    yaml_dict = {}
    with open(yaml_file_path) as yaml_stream:
        try:
            yaml_dict = yaml.load(yaml_stream, Loader=yaml.Loader)
        except yaml.YAMLError as yaml_exc:
            print("An exception occured while reading YAML file "
                  "({yaml}). {exception}".format(yaml=yaml_file_path,
                                                 exception=yaml_exc))
    return yaml_dict


def init_parser():
    """ Instanciate and returns a parser with a few dummy arguments

    An extensive documentation of argparse is available
    https://docs.python.org/3/library/argparse.html
    A gentle introduction is available here
    https://docs.python.org/3/howto/argparse.html

    TL;DR
    import argparse
    parser = argparse.ArgumentParser()
    parser.parse_args()
    """
    # instanciate the parser
    arg_parser = argparse.ArgumentParser(description='Script parser')

    # add parser arguments

    # required arg with no default value
    arg_parser.add_argument(
        '-a',  # short argument name
        '--argument',  # long argument name
        action='store',  # store the argument value
        required=True,  # flag, script will exit if not given
        metavar="ARGUMENT A",  # variable value example
        dest='arg',  # name used to access the argument value later on
        help='This is a standard required argument.'
    )

    # non required arg with default
    arg_parser.add_argument(
        '-b',  # only a short name
        action='store',
        metavar="ARGUMENT B",  # variable value example
        default="default_b",  # default value for b
        dest='arg_b',  # name used to access the argument value later on
        help='This is a standard non required argument, but it has a '
             'default value'
    )

    # flag arguments (true/false)
    arg_parser.add_argument(
        '-t',
        '--true-flag',
        action='store_true', # could be store_false
        required=False,
        dest='tflg',
        help='This is a flag argument. True if set, default to None'
    )
    arg_parser.add_argument(
        '-f',
        '--false-flag',
        action='store_false', # could be store_false
        required=False,
        dest='fflg',
        help='This is a flag argument. False if set, default to True'
    )

    return arg_parser


def main(script_kwargs):
    print_dict(script_kwargs, "Script kwargs")

    yaml_config_path = get_yaml()
    yaml_config_dict = import_yaml_config_as_dict(yaml_config_path)
    print_dict(script_kwargs, "Yaml configuration")

    print("\nExamples to access values :\n")
    ex_hash = yaml_config_dict['example']['ahash']
    type_ex_hash = type(ex_hash)
    print("yaml_config_dict['example']['ahash'] : {val} ({type_val})"
          .format(val=ex_hash, type_val=type_ex_hash))

    ex_arr = yaml_config_dict['example']['anarray']
    type_ex_arr = type(ex_arr)
    print("yaml_config_dict['example']['anarray'] : {val}, ({type_val})"
          .format(val=ex_arr, type_val=type_ex_arr))

    ex_val = yaml_config_dict['global']['projectpath']
    print("yaml_config_dict['global']['projectpath'] : {}".format(ex_val))



if __name__ == "__main__":
    script_parser = init_parser()
    if (len(sys.argv) < 1):  # User did not provide any argument
        script_parser.parse_args(['-h'])  # Help that guy!

    script_args = script_parser.parse_args(sys.argv[1:])
    # script_args is a 'Namespace'
    # make script_args a dictionary
    script_kwargs = vars(script_args)
    main(script_kwargs)







