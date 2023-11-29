# GitHub Manager (GHM)
## currently under development, accepting contributions

The GitHub Management Tool (GHM) is a script designed to simplify and automate various GitHub repository and team management tasks. This tool allows users to create new teams, attach repositories to teams, or execute a full process based on a JSON mapping.

## Features

- **Create Team and Attach Repos**: Create a new team in a specified organization and attach repositories to it.
- **Only Attach Repos**: Attach repositories to an existing team.
- **Full Process (from JSON mapping)**: Execute a full process based on a predefined JSON mapping. This includes creating teams and attaching repositories as specified in the mapping.

## Requirements

- Bash environment
- GitHub CLI installed and authenticated
- JQ (Command-line JSON processor)

## Usage

Run the script in your bash terminal:

```bash
./ghm.sh
```

After executing the script, you will be prompted to choose one of the following actions:

1. **Create Team and Attach Repos**: You will need to enter the team's name in 'org/teamname' format and specify repositories to attach in 'org/repo,org/repo2' format or 'org/*' for all repositories in the organization.

2. **Only Attach Repos**: You will need to enter an existing team's name in 'org/teamname' format and specify repositories to attach.

3. **Full Process (from JSON mapping)**: The script will read a file named `gh-team-mapping.json` and process the teams and repositories based on the mapping defined in this file.

The script will output the username it's acting under, the number of teams created, and the number of repositories attached. It also displays the total time taken to execute the operations.

## JSON Mapping Format (for Full Process)

The JSON mapping file (`gh-team-mapping.json`) should follow this format:

```json
[
  {
    "team_name": "example-team",
    "organizations": ["org1", "org2"],
    "repos": ["org1/repo1", "org1/repo2"]
  },
  ...
]
```

Each object in the array represents a team and includes:
- `team_name`: The name of the team to be created or used.
- `organizations`: An array of organizations where the team should be created or is located.
- `repos`: An array of repositories (in 'org/repo' format) to attach to the team.

## Note

- This script uses the GitHub CLI and JQ, and it's essential that both are installed and configured on your machine.
- The script should be run with the necessary permissions to create teams and attach repositories in the specified organizations.
