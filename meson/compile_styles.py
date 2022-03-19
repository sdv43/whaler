#!/usr/bin/env python3

import os
import sys
import subprocess

classTpl = """
class CssStyles : Object {{
    {properties}
}}
"""
classPropertyTpl = 'public string {name} {{ get; default = """{css}"""; }}\n'

input_files = sys.argv[1:-1]
output_file = sys.argv[-1]
properties = ''

for file in input_files:
    file_name = os.path.basename(file)
    property_name = os.path.splitext(file_name)[0].replace('-', '_')

    print ('compile', file_name)

    output = subprocess.run(
        'sass {file}'.format(file=file),
        capture_output = True,
        shell = True,
        text = True,
        check = True,
    )
    
    properties += classPropertyTpl.format(name=property_name, css=output.stdout)


with open(output_file, "w") as vala_class:
    vala_class.write(classTpl.format(properties=properties))

print('Done!')