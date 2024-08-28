import re
from jinja2 import Environment, FileSystemLoader

# Define the paths
dockerfile_path = "../../Dockerfile"
requirements_path = "../../requirements.txt"
template_path = "README_template.j2"
output_path = "../../README.md"

# Initialize a list to store tool and dependency information
tools = []
dependencies = []

# Regular expression to match ARG lines that define tool versions
version_pattern = re.compile(r'ARG\s+(\w+)_VERSION=([\w.]+)')

# Read the Dockerfile and extract tool versions
with open(dockerfile_path, 'r') as dockerfile:
    for line in dockerfile:
        # Search for ARG lines to get tool versions
        version_match = version_pattern.search(line)
        if version_match:
            tool_name = version_match.group(1).replace(
                '_', ' ').title().replace('version', '').strip()
            tool_version = version_match.group(2)
            tools.append((tool_name, tool_version))

# Read the requirements.txt and extract dependencies
with open(requirements_path, 'r') as requirements_file:
    for line in requirements_file:
        # Each line should have the format `package==version`
        if '==' in line:
            dependency_name, dependency_version = line.strip().split('==')
            dependencies.append((dependency_name, dependency_version))

# Generate the Markdown table for tools
markdown_table = "| Tool/Dependency | Version |\n|----------------|---------|\n"
for tool in tools:
    markdown_table += f"| {tool[0]} | {tool[1]} |\n"

# Add the dependencies to the Markdown table
for dependency in dependencies:
    markdown_table += f"| {dependency[0]} | {dependency[1]} |\n"

# Setup Jinja2 environment
env = Environment(loader=FileSystemLoader('.'))
template = env.get_template(template_path)

# Render the README content using the Jinja template
rendered_content = template.render(tools_table=markdown_table)

# Write the rendered content to the README file
with open(output_path, 'w') as output_file:
    output_file.write(rendered_content)

print(f"README.md has been generated with the tools table and dependencies.")
