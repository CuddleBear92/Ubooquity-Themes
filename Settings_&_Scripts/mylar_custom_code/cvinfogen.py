import argparse
import os
import re

CVID_REGEX = re.compile(r'CVID(\d+)', re.IGNORECASE)

argument_parser = argparse.ArgumentParser()
argument_parser.add_argument('path')
argument_parser.add_argument('--prefix', '-p', default='https://comicvine.gamespot.com/1/4050-')
argument_parser.add_argument('--overwrite', '-f', action='store_true')


def has_cvid(name):
    return bool(CVID_REGEX.search(name))


def yield_paths(path, predicate=lambda path: path):
    for path, directories, file_names in os.walk(path):
        if predicate(path):
            yield path

        for file_name in file_names:
            file_path = os.path.join(path, file_name)
            if predicate(file_path):
                yield file_path


def main(arguments):
    for path in yield_paths(arguments.path, os.path.isdir):
        folder = os.path.basename(path)
        match = CVID_REGEX.search(folder)
        if not match:
            continue

        cvid = match.group(1)
        cvid_path = os.path.join(path, 'cvinfo')
        if not os.path.exists(cvid_path) or arguments.overwrite:
            print('Writing CVID file:', cvid_path)
            with open(cvid_path, 'w', encoding='UTF-8') as file:
                file.write(arguments.prefix + cvid)


if __name__ == '__main__':
    arguments = argument_parser.parse_args()
    argument_parser.exit(main(arguments))
