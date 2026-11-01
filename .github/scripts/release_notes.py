#!/usr/bin/env python3
"""Extract the exact pubspec version's changelog section for store releases."""
import argparse
import os
import pathlib
import re
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--platform', choices=('android', 'ios'), required=True)
args = parser.parse_args()
pubspec = pathlib.Path('pubspec.yaml').read_text(encoding='utf-8')
match = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', pubspec, re.M)
if not match:
    sys.exit('pubspec.yaml must contain version: X.Y.Z+build')
version, build = match.groups()
changelog = pathlib.Path('CHANGELOG.md').read_text(encoding='utf-8')
sections = list(re.finditer(r'^## \[([^\]]+)\][^\n]*$', changelog, re.M))
matches = [i for i, section in enumerate(sections) if section.group(1) == version]
if len(matches) != 1:
    sys.exit(f'Expected exactly one changelog section for {version}; found {len(matches)}')
i = matches[0]
if i != 0:
    sys.exit(f'Version {version} must be the latest changelog section')
section = changelog[sections[i].start():sections[i + 1].start() if i + 1 < len(sections) else len(changelog)].strip()
body = changelog[sections[i].end():sections[i + 1].start() if i + 1 < len(sections) else len(changelog)].strip()
notes = re.sub(r'^#{3,6}\s+.*\n?', '', body, flags=re.M)
notes = re.sub(r'\n\s*\n+', '\n', notes).strip()
if not notes:
    sys.exit(f'Changelog section for {version} is empty')
override = os.environ.get('RELEASE_NOTES_OVERRIDE', '').strip()
if override:
    notes = override
limit = 500 if args.platform == 'android' else 4000
if len(notes) > limit:
    sys.exit(f'{args.platform} release notes are {len(notes)} characters; limit is {limit}. Provide a shorter release notes override or shorten the changelog.')
pathlib.Path('release-notes.txt').write_text(notes + '\n', encoding='utf-8')
pathlib.Path('release-body.md').write_text(section + '\n', encoding='utf-8')
with open(pathlib.Path(os.environ['GITHUB_OUTPUT']), 'a', encoding='utf-8') as out:
    out.write(f'version={version}\nbuild={build}\ntag=YakiHonne-{version}\n')
