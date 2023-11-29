#!/bin/bash

# get github username to remove from created groups
GH_USERNAME="$(gh api user -q ".login")"
echo "acting username is: $GH_USERNAME"

# Metrics and time init
total_teams=0
total_repos=0
start_time=$(date +%s)

echo "Select an action:"
options=("Create Team and Attach Repos" "Only Attach Repos" "Full Process (from JSON mapping)")
select opt in "${options[@]}"; do
    case $opt in
        "Create Team and Attach Repos")
            read -p "Enter team in 'org/teamname' format: " team_input
            org=$(echo "${team_input%%/*}" | awk '{print tolower($0)}') # Convert to lowercase for org SLUG
            team_name="${team_input#*/}"
            team_slug=$(echo "${team_name// /-}" | awk '{print tolower($0)}') # Replace spaces with hyphens and convert to lowercase for team SLUG
            read -p "Enter repos to attach in 'org/repo,org/repo2' format or 'org/*' for all: " repos_input
            action="create_and_attach"
            break
            ;;
        "Only Attach Repos")
            read -p "Enter team in 'org/teamname' format to which repos will be attached: " team_input
            org=$(echo "${team_input%%/*}" | awk '{print tolower($0)}') # Convert to lowercase for org SLUG
            team_name="${team_input#*/}"
            team_slug=$(echo "${team_name// /-}" | awk '{print tolower($0)}') # Replace spaces with hyphens and convert to lowercase for team SLUG
            read -p "Enter repos to attach in 'org/repo,org/repo2' format or 'org/*' for all: " repos_input
            action="attach_only"
            break
            ;;
        "Full Process (from JSON mapping)")
            data=$(cat gh-team-mapping.json)
            action="full_process"
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

attach_repos_to_team() {
    local team_slug="$1"
    shift
    IFS=',' read -ra ADDR <<< "$@"
    for repo in "${ADDR[@]}"; do
        if [[ $repo == *"/*" ]]; then
            org_to_list=$(echo "${repo%/*}" | awk '{print tolower($0)}') # Convert to lowercase for org SLUG
            all_repos=($(gh repo list $org_to_list --limit 1000 | awk '{print $1}'))
            for repo_name in "${all_repos[@]}"; do
                echo "Attaching repo $repo_name to team $team_slug in organization $org_to_list"
                gh api --method PUT -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/orgs/$org_to_list/teams/$team_slug/repos/$repo_name" -f permission='MGMT'
                ((total_repos++))
            done
        else
            repo_org=$(echo "${repo%%/*}" | awk '{print tolower($0)}') # Convert to lowercase for org SLUG
            repo_name=$(echo "${repo##*/}" | awk '{print tolower($0)}') # Convert to lowercase for repo SLUG
            echo "Attaching repo $repo_name to team $team_slug in organization $repo_org"
            gh api --method PUT -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/orgs/$repo_org/teams/$team_slug/repos/$repo_org/$repo_name" -f permission='MGMT'
            ((total_repos++))
        fi
    done
}

# Process based on action
case $action in
    "create_and_attach")
        echo "Creating team $team_name in organization $org"
        gh api --method POST -H "Accept: application/vnd.github+json" "https://api.github.com/orgs/$org/teams" -f name="$team_name" -f privacy='closed'
        ((total_teams++))

        attach_repos_to_team "$team_slug" "$repos_input"
        ;;
    "attach_only")
        attach_repos_to_team "$team_slug" "$repos_input"
        ;;
    "full_process")
        length=$(echo $data | jq '. | length')

        for (( i=0; i<$length; i++ )); do
            team_name=$(echo $data | jq -r --argjson i $i '.[$i].team_name')
            team_slug="${team_name// /-}" # Replace spaces with hyphens to form a slug
            echo "Processing team: $team_name"

            org_length=$(echo $data | jq --argjson i $i '.[$i].organizations | length')
            for (( j=0; j<$org_length; j++ )); do
                org=$(echo $data | jq -r --argjson i $i --argjson j $j '.[$i].organizations[$j]')
                echo "Organization: $org"

                if [[ $org == "all" ]]; then
                    all_orgs=($(gh org list | awk '{print $1}'))
                else
                    all_orgs=($org)
                fi

                echo "All Orgs: ${all_orgs[@]}"

                for current_org in "${all_orgs[@]}"; do
                    echo "Creating team $team_name in organization $current_org"
                    gh api --method POST -H "Accept: application/vnd.github+json" "https://api.github.com/orgs/$current_org/teams" -f name="$team_name" -f privacy='closed'
                    ((total_teams++))
                done
            done

            repo_length=$(echo $data | jq --argjson i $i '.[$i].repos | length')
            for (( k=0; k<$repo_length; k++ )); do
                repo=$(echo $data | jq -r --argjson i $i --argjson k $k '.[$i].repos[$k]')
                repo_org=$(echo $repo | cut -d'/' -f1)
                repo_name=$(echo $repo | cut -d'/' -f2)

                echo "Attaching repo $repo to team $team_name in organization $repo_org"
                gh api --method PUT -H "Accept: application/vnd.github+json" "https://api.github.com/orgs/$repo_org/teams/$team_slug/repos/$repo_org/$repo_name" -f permission='admin'
                ((total_repos++))
            done
        done
        ;;
esac

# time & metrics
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
minutes=$((elapsed_time / 60)) ; seconds=$((elapsed_time % 60))
echo "Created $total_teams teams and attached $total_repos repos in $minutes minutes and $seconds seconds."
