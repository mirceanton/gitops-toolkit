import re
from jinja2 import Environment, FileSystemLoader

# Define the paths
dockerfile_path = "../../Dockerfile"
requirements_path = "../../requirements.txt"
template_path = "README_template.j2"
output_path = "../../README.md"

# Initialize a list to store tool and dependency information
tools = []

# =================================================================================================
# Extract Tool Versions From Dockerfile ARGs
# =================================================================================================
# Regular expression to match ARG lines that define tool versions
regex = r"ARG\s+([A-Z0-9_]+)_VERSION=([\w\.\-]+)"

# Read the Dockerfile and extract matches
def extract_versions(file_path):
    try:
        with open(file_path, 'r') as file:
            content = file.read()
            matches = re.findall(regex, content)
            return matches
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return []

# Process the Dockerfile
print("Extracting version numbers from Dockerfile...")
dockerfile_tool_versions = extract_versions(dockerfile_path)
if dockerfile_tool_versions:
    print(f"Found {len(dockerfile_tool_versions)} tools.")
else:
    print("No matches found or file is empty.")
    exit(1)

# Append dockerfile versions
for tool in dockerfile_tool_versions:
    tool_name = tool[0].replace('_', ' ').title().replace('version', '').strip()
    tool_version = tool[1]
    tools.append((tool_name, tool_version))

# =================================================================================================
# Extract Tool Versions From Python Requirements
# =================================================================================================
# Read the requirements.txt and extract dependencies
def extract_pip_versions(file_path):
    dependencies = []
    try:
        with open(file_path, 'r') as file:
            for line in file:
                # Each line should have the format `package==version`
                if '==' in line:
                    dependency_name, dependency_version = line.strip().split('==')
                    dependencies.append((dependency_name, dependency_version))
            return dependencies
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return []

# Process the requirements file
print("Extracting version numbers from requirements.txt ...")
python_tool_versions = extract_pip_versions(requirements_path)
if python_tool_versions:
    print(f"Found {len(python_tool_versions)} tools.")
else:
    print("No matches found or file is empty.")
    exit(1)

# Append python versions
for tool in python_tool_versions:
    tools.append((tool[0], tool[1]))

# Generate the Markdown table for tools
markdown_table = "| Tool/Dependency | Version |\n|----------------|---------|\n"
for tool in tools:
    markdown_table += f"| {tool[0]} | {tool[1]} |\n"

# Setup Jinja2 environment
env = Environment(loader=FileSystemLoader('.'))
template = env.get_template(template_path)

# Render the README content using the Jinja template
rendered_content = template.render(tools_table=markdown_table)

# Write the rendered content to the README file
with open(output_path, 'w') as output_file:
    output_file.write(rendered_content)

print(f"README.md has been generated with the tools table and dependencies.")
