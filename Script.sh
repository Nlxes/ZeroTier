#!/bin/bash
source .env #Api and network id here

domains=("adress1.com" "adress2.com" "adress3.com") #Pool of adresses

json_data=$(curl -s -H "Authorization: bearer $api_token" "https://api.zerotier.com/api/v1/network/$zerotier_network_id")

route_updates=({\"target\":\"192.168.192.0/24\"}) #Route for LAN (Optional)

for domain in "${domains[@]}"; do
ip_addresses=$(nslookup "$domain" | awk '/^Address: / { print $2 }')
    for ip_address in $ip_addresses; do
        if [[ "$ip_address" == *:* ]]; then
            continue
        fi
        if [ -n "$ip_address" ]; then
            route_updates+=("{\"target\": \"$ip_address/32\", \"via\": \"192.168.192.13\"}")
        else
            echo "Cannot find IP-adress for $domain"
        fi
    done
done

if [ ${#route_updates[@]} -gt 0 ]; then
    routes_string=$(IFS=, ; echo "[${route_updates[*]}]")
    json_data=$(echo "$json_data" | jq --argjson routes "$routes_string" '.config.routes = $routes')
    # echo "Your JSON:"
    # echo "$json_data"
    curl -s -o /dev/null -X POST "https://api.zerotier.com/api/v1/network/$zerotier_network_id" \
         -H "Authorization: bearer $api_token" \
         -H "Content-Type: application/json" \
         -d "$json_data"
else
    echo "No IP addresses found, check your network or domain names."
fi