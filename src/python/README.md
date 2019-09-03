Two script snippets are available here:

1. cli_script_example
2. <a href="#advex"></a> cli_script_example_with_subparser

\[[2](#advex)\] is a bit more advanced, but exposes a simple approach to have a command line interface that can be used to call subcommand in a script (making use of subparsers). Subparsers are used when a script performs different functions. This is e.g. the case of `git` which uses subcommands (like `git status`, `git add`, etc.).

# cli_script_example

[This basic script](cli_script_example.py) snippet shows how to

1. initialise and use an argument parser (uses the python argparse library)
2. parse a yaml file and make it as a python dictionary

# cli_script_example_with_subparser

>>>
Splitting up functionality this way can be a particularly good idea when a program performs several different functions which require different kinds of command-line arguments.
>>>
[argparse suparsers documentation](https://docs.python.org/3/library/argparse.html#sub-commands)

[This script](cli_script_example_with_subparser.py) snippet shows how to

1. initialise and use an argument parser like for previous section, with the addition of subparsers usage to split subcommands


# references

## argparse

- [tutorial](https://docs.python.org/3/howto/argparse.html)
- [documentation](https://docs.python.org/3/library/argparse.html)


