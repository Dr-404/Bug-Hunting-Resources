#!/bin/bash

# This following tools need to install for this recon tools


# sudo apt install golang-go ( Install `go` )

# Add the Go binary directory to your PATH and source the .bashrc
 #echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc && source ~/.bashrc

# Verify the binary is accessible
  #which my_go_program
# go install github.com/tomnomnom/httprobe@latest ( Install `httprobe` )
#go install github.com/projectdiscovery/katana/cmd/katana@latest ( Install `katana` )
# go install github.com/tomnomnom/waybackurls@latest ( Install `waybackurls` )



# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Global Variables
domain="nuffic.nl"
api_key='gh8YRFdULNZz5KenwNQG0Jjj29NvvMI9'
output_dir="output"




# To store Tempory result and delet after fin result

tmp_active_domain="$output_dir/active_sub.txt"
tmp_inactive_domain="$output_dir/inactive_sub.txt"

# Final Output Dir

subdomain_file="$output_dir/new_subdomains.txt"
active_domain="$output_dir/active_subdomains.txt"
inactive_domain="$output_dir/inactive_subdomains.txt"
public_ips="$output_dir/public_ips.txt"
urls="$output_dir/urls.txt"
js_files="$output_dir/js_files.txt"

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

    # Reomve Temporary Active Resultls

    awk -F'//' '{print $2}' "$tmp_active_domain" | sort | uniq > $active_domain
    rm -rf $tmp_active_domain

    echo -e "[${GREEN}+${NC}] Adding active subdomains to $active_domain"

    # Remove Tempory Inactive Result

    awk -F'//' '{print $2}' "$tmp_inactive_domain" | sort | uniq > $inactive_domain
    rm -rf $tmp_inactive_domain

    echo -e "[${RED}-${NC}] Adding inactive subdomains to $inactive_domain"
    

}


function public_IP_Finder {

    response_ips=$(curl -s --request GET \
     --url https://api.securitytrails.com/v1/history/$domain/dns/a \
     --header "APIKEY: $api_key" \
     --header 'accept: application/json')

    echo "$response_ips" | jq -r '.records[] | select(.organizations[0] != "Cloudflare, Inc.") | .values[].ip' | sort | uniq > $public_ips

}

function finding_urls {

    # using katana

    katana -u $active_domain 2>/dev/null  > $urls

    #echo "Success Katana"

    cat $active_domain | waybackurls | sort | uniq >> $urls

    echo "[+] Adding urls to $urls file"


    # findng js

    cat $urls | grep -F ".js" > $js_files

    echo "[+] Adding JS file to $js_files file"




}





# Main Function
#==============# 

check_output_folder
subdomain_finder
add_http
validate_subdomain
clean_result
public_IP_Finder
finding_urls