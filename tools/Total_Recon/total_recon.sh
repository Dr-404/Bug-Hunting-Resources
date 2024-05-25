#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Global Variables
domain="mytel.com.mm"
api_key='DDKfDTHXTY17r1qYBq78FbQjvFa93Adw'
output_dir="output"

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
    echo -e "[${GREEN}+${NC}] Adding subdomains to $PWD/$output_dir/subdomains.txt"
}




function add_http {

	cat "$output_dir/subdomains.txt" | httprobe >> "$output_dir/new_subdomains.txt"
}


function validate_subdomain {

	subdomain_file="$output_dir/new_subdomains.txt"
    active_subdomains_file="$output_dir/active_subdomains.txt"
    inactive_subdomains_file="$output_dir/inactive_subdomains.txt"

    if [ ! -f "$subdomain_file" ]; then
    	echo -e "[${RED}ERROR${NC}] Subdomain file $subdomain_file does not exist. Exiting."
    	return 1

    fi

    > "$active_subdomains_file"
    > "$inactive_subdomains_file"

    
    while IFS= read -r subdomain; do
        
        http_status=$(curl -s -o /dev/null -w "%{http_code}" "$subdomain")
        https_status=$(curl -s -o /dev/null -w "%{http_code}" "$subdomain")

        if [[ "$http_status" -eq 200 || "$http_status" -eq 301 || "$http_status" -eq 308||"$https_status" -eq 403 ]]; then
            echo -e "${GREEN}$subdomain is active (HTTP) with status $http_status${NC}"
            echo "$subdomain" >> "$active_subdomains_file"
        else
            echo -e "${RED}$subdomain is not active${NC}with status $https_status"
            echo "$subdomain" >> "$inactive_subdomains_file" 
        fi
    done < "$subdomain_file"
    rm -rf $subdomain_file


    # http_status=$(httpx -status-code -l "$subdomain_file" 2>/dev/null)    

    # echo "$http_status\n" | grep -E '200|301' | awk '{print $1 $2}'
    # echo "$http_status\n" | grep '\b4[0-9][0-9]\b' | awk '{print $1 $2}'

}

# function validate {
  

#     cat $subdomain_file | httprobe >> "$output_dir/new_subdomains.txt"
#     new_subdomain="$output_dir/new_subdomains.txt"

#     while IFS= read -r sub; do
#     	#httprobe $sub > 
#     	echo $sub
#         http_status=$(httpx -status-code -u "$sub")
        
#         echo "........................"
        
#         if [[ "$http_status" =~ ^(200|301)$ ]]; then
#             echo "$subdomain" >> "$active_subdomains_file"
#             echo "Success 0"
#         else
#             echo "$subdomain" >> "$inactive_subdomains_file"
#             echo "Success 2"
#         fi
        
#     done < "$new_subdomain"

#     echo -e "${GREEN}[+] Check and Validate subdomain ...${NC}"
#     echo -e "${RED}[-] Removing inactive subdomain and export as $inactive_subdomains_file${NC}"
#     echo -e "${GREEN}[+] Adding valid subdomain to $PWD/$output_dir/active_subdomains_file.txt${NC}"
# }

check_output_folder
subdomain_finder
add_http
validate_subdomain