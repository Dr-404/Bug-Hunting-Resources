#!/bin/bash

# This following tools need to install for this recon tools


# sudo apt install golang-go ( Install `go` )
# go install github.com/tomnomnom/httprobe@latest ( Install `httprobe` )



# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Global Variables
domain="springdevelopmentbank.com"
api_key='DDKfDTHXTY17r1qYBq78FbQjvFa93Adw'
output_dir="output"


subdomain_file="$output_dir/new_subdomains.txt"

# To store Tempory result and delet after fin result

tmp_active_domain="$output_dir/active_sub.txt"
tmp_inactive_domain="$output_dir/inactive_sub.txt"

# Final Output Dir

active_domain="$output_dir/active_subdomains.txt"
inactive_domain="$output_dir/inactive_subdomains.txt"

function check_output_folder {
    if [ ! -d "$output_dir" ]; then
        echo -e "[${GREEN}+${NC}] Creating $output_dir for reporting..."
        mkdir "$output_dir"
    else
        echo -e "[${YELLOW}!${NC}] $output_dir directory already exists."
    fi
}

function subdomain_finder {
    response=$(curl -s --request GET \
        --url "https://api.securitytrails.com/v1/domain/$domain/subdomains" \
        --header "APIKEY: $api_key" \
        --header 'accept: application/json')

    if [ -z "$response" ]; then
        echo -e "[${RED}ERROR${NC}] No subdomains found for $domain. Exiting."
        exit 1
    fi

    echo "$response" | jq -r '.subdomains[]' | while read -r subdomain; do
        echo "$subdomain.$domain" >> "$output_dir/subdomains.txt"
    done
    
}




function add_http {

	cat "$output_dir/subdomains.txt" | httprobe >> "$output_dir/new_subdomains.txt"
}


function validate_subdomain {

	

    

    if [ ! -f "$subdomain_file" ]; then
    	echo -e "[${RED}ERROR${NC}] Subdomain file $subdomain_file does not exist. Exiting."
    	return 1

    fi

    > "$tmp_active_domain"
    > "$tmp_inactive_domain"

    
    while IFS= read -r subdomain; do
        
        http_status=$(curl -s -o /dev/null -w "%{http_code}" "$subdomain")
        https_status=$(curl -s -o /dev/null -w "%{http_code}" "$subdomain")

        if [[ "$http_status" -eq 200 || "$http_status" -eq 301 || "$http_status" -eq 308||"$https_status" -eq 403 ]]; then

            #echo -e "${GREEN}$subdomain is active (HTTP) with status $http_status${NC}"

            echo "$subdomain" >> "$tmp_active_domain"
            
        else
            #echo -e "${RED}$subdomain is not active${NC}with status $https_status"

            echo "$subdomain" >> "$tmp_inactive_domain" 
        fi
    done < "$subdomain_file"

    

    

}

function clean_result {

    # Remove Unnessary Files

    rm $output_dir/subdomains.txt
    rm $subdomain_file

    # Reomve Temporary Active Result

    awk -F'//' '{print $2}' "$tmp_active_domain" | sort | uniq > $active_domain
    rm -rf $tmp_active_domain

    echo -e "[${GREEN}+${NC}] Adding active subdomains to $active_domain"

    # Remove Tempory Inactive Result

    awk -F'//' '{print $2}' "$tmp_inactive_domain" | sort | uniq > $inactive_domain
    rm -rf $tmp_inactive_domain

    echo -e "[${RED}-${NC}] Adding inactive subdomains to $inactive_domain"
    

}


# Main Function
#==============# 

check_output_folder
subdomain_finder
add_http
validate_subdomain
clean_result