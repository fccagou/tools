# First version from openAI
#
import yaml

def parse_gitlab_ci(file_path):
    """Parse the .gitlab-ci.yml file and return its contents."""
    with open(file_path, 'r') as file:
        return yaml.safe_load(file)

def generate_dockerfile(stage_name, stage_info):
    """Generate a Dockerfile based on the stage's configuration."""
    dockerfile_lines = [
        f"# Dockerfile for stage: {stage_name}",
        "FROM {image}",
        "",
        "# Install dependencies if necessary",
    ]

    # Add before_script commands if present
    if 'before_script' in stage_info:
        dockerfile_lines.append("# Before script:")
        dockerfile_lines.append(f"RUN {stage_info['before_script']}")

    # Add script commands (the main commands for the stage)
    dockerfile_lines.append("# Main script:")
    for command in stage_info.get('script', []):
        dockerfile_lines.append(f"RUN {command}")

    # Add after_script commands if present
    if 'after_script' in stage_info:
        dockerfile_lines.append("# After script:")
        dockerfile_lines.append(f"RUN {stage_info['after_script']}")

    # Handle services (e.g., databases) if necessary
    if 'services' in stage_info:
        dockerfile_lines.append("# Services:")
        for service in stage_info['services']:
            dockerfile_lines.append(f"RUN docker-compose up -d {service}")

    return "\n".join(dockerfile_lines)

def create_dockerfiles_for_all_stages(ci_data):
    """Create Dockerfiles for all stages defined in the .gitlab-ci.yml."""
    dockerfiles = {}

    for stage_name, stage_info in ci_data['stages'].items():
        dockerfile = generate_dockerfile(stage_name, stage_info)
        dockerfiles[stage_name] = dockerfile

    return dockerfiles

def save_dockerfiles(dockerfiles):
    """Save Dockerfiles to individual files."""
    for stage, dockerfile in dockerfiles.items():
        with open(f"Dockerfile_{stage}", 'w') as file:
            file.write(dockerfile)

if __name__ == "__main__":
    # Path to your .gitlab-ci.yml file
    gitlab_ci_file = '.gitlab-ci.yml'

    # Parse the .gitlab-ci.yml file
    ci_data = parse_gitlab_ci(gitlab_ci_file)

    # Generate Dockerfiles for each stage
    dockerfiles = create_dockerfiles_for_all_stages(ci_data)

    # Save Dockerfiles
    save_dockerfiles(dockerfiles)

    print("Dockerfiles have been generated and saved.")
