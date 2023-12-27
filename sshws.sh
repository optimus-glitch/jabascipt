#!/bin/bash

release=$(lsb_release -r | awk '{print $2}')

if [[ "$release" == "20.04" ]]; then
    echo -e "\033[1;32m UBUNTU 20.04 DETECTED, SYSTEM SUPPORTED\033[0m"
    echo -e "\033[1;34m PROCEEDING WITH INSTALLATION\033[0m"
    sleep 1.5

else
    echo -e "\033[1;31m\e[38;5;208m WARNING: This script is designed to work only on Ubuntu 20.04. Do you want to proceed anyway? \033[0m"
    read -p "(y/n) " answer
    if [[ "$answer" =~ [Yy] ]]; then
        echo -e "\033[1;34m PROCEEDING WITH INSTALLATION\033[0m"
        sleep 1.5

    else
        echo "EXITING...."
        sleep 1.5
        exit 1
    fi
fi

RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'
while true; do
    echo -e "${ORANGE}How many times do you want to schedule a reboot? (1 or 2):${NC}"
    read num_reboots
    if [[ $num_reboots -eq 1 || $num_reboots -eq 2 ]]; then
        break
    else
        echo -e "${RED}Invalid input. Server autoreboot is crucial for a virtual Machine. Please enter either 1 or 2.${NC}"
    fi
done

if [ $num_reboots -eq 1 ]; then
    echo -e "${ORANGE}Enter the reboot time in 24-hour HHMM format:${NC}"
    read reboot_time
    while [[ ! $reboot_time =~ ^[0-2][0-9][0-5][0-9]$ ]]; do
        echo -e "${ORANGE}Invalid input. Please enter the reboot time in 24-hour HHMM format:${NC}"
        read reboot_time
    done
    reboot_time=$(date --date="$reboot_time -3 hours" +"%H:%M")
    (crontab -l 2>/dev/null; echo "15 $reboot_time * * * /sbin/reboot") | crontab -
    echo -e "${ORANGE}Reboot scheduled for $reboot_time every day.${NC}"
elif [ $num_reboots -eq 2 ]; then
    echo -e "${ORANGE}Enter the first reboot time in 24-hour HHMM format:${NC}"
    read reboot_time1
    while [[ ! $reboot_time1 =~ ^[0-2][0-9][0-5][0-9]$ ]]; do
        echo -e "${ORANGE}Invalid input. Please enter the reboot time in 24-hour HHMM format:${NC}"
        read reboot_time1
    done
    reboot_time1=$(date --date="$reboot_time1 -3 hours" +"%H:%M")
    echo -e "${ORANGE}Enter the second reboot time in 24-hour HHMM format:${NC}"
    read reboot_time2
    while [[ ! $reboot_time2 =~ ^[0-2][0-9][0-5][0-9]$ ]]; do
        echo -e "${ORANGE}Invalid input. Please enter the reboot time in 24-hour HHMM format:${NC}"
        read reboot_time2
    done
    reboot_time2=$(date --date="$reboot_time2 -3 hours" +"%H:%M")
    (crontab -l 2>/dev/null; echo "15 $reboot_time1 * * * /sbin/reboot") | crontab -
    (crontab -l 2>/dev/null; echo "15 $reboot_time2 * * * /sbin/reboot") | crontab -
    echo -e "AUTO REBOOT UPDATED"
fi

iptables -P INPUT ACCEPT 
iptables -P OUTPUT ACCEPT 
iptables -P FORWARD ACCEPT 
iptables -F 
sudo cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.bak 
sudo truncate -s 0 /etc/iptables/rules.v4

ufw allow 22,443,80/tcp
ufw --force enable

systemctl stop stunnel4 nodews1 badvpn apache2 nginx


rm -f /etc/banner.html
rm -f /etc/stunnel/*


yellow=$(tput setaf 3)
bold=$(tput bold)
reset=$(tput sgr0)

read -p "${yellow}${bold}Enter domain name pointing to server: ${reset}" domain_name

read -p "${yellow}${bold}Enter username for use in ssh ws connection: ${reset}" user_name

read -p "${yellow}${bold}Enter password for the above: ${reset}" pass_word

read -p "${yellow}${bold}Enter email address for cert verification: ${reset}" email_address
echo

YELLOW=$(tput setaf 3)

RED='\033[0;31m'

GREEN=$(tput setaf 2)

echo -e "${GREEN}Welcome to the banner file creator! This is The message displayed to users connecting to vpn service"
echo -e "${YELLOW}How many lines do you want in the banner? (maximum 4)"
read num_lines

while [[ ! "$num_lines" =~ ^[1-4]$ && ! -z "$num_lines" ]]; do
    echo -e "${RED}Invalid input. Please enter a number between 1 and 4"
    read num_lines
done

colors=("red" "green" "blue" "white" "brown")
font_sizes=("1: small" "2: medium" "3: large")
alignments=("1: left" "2: center" "3: right")

cat > /etc/banner.html <<EOF
<!DOCTYPE html>
<html>
<body>
EOF

for (( i=1; i<=$num_lines; i++ )); do
    echo -e "${GREEN}Supported colors: ${colors[@]}"
    echo -e "${YELLOW}Enter the string for line $i:"
    read line_text

    while [[ $(echo $line_text | wc -w) -gt 7 || -z "$line_text" ]]; do
        echo -e "${RED}Invalid input. Please enter a string with maximum 7 words"
        read line_text
    done

    echo -e "${GREEN}Supported font sizes: ${font_sizes[@]}"
    echo -e "${YELLOW}Enter the font size for line $i:"
    read font_size

    while [[ ! "$font_size" =~ ^[1-3]$ && ! -z "$font_size" ]]; do
        echo -e "${RED}Invalid input. Please enter a supported font size number.(Between 1 and 3)"
        read font_size
    done

    echo -e "${GREEN}Supported alignments: ${alignments[@]}"
    echo -e "${YELLOW}Enter the alignment for line $i:"
    read alignment

    while [[ ! "$alignment" =~ ^[1-3]$ && ! -z "$alignment" ]]; do
        echo -e "${RED}Invalid input. Please enter a supported alignment number.(Between 1 and 3"
        read alignment
    done

    echo -e "${GREEN}Supported colors: ${colors[@]}"
    echo -e "${YELLOE}Enter the font color for line $i:"
    read line_color

    while [[ ! "${colors[@]}" =~ (^|[[:space:]])"$line_color"($|[[:space:]]) && ! -z "$line_color" ]]; do
        echo -e "${RED}Invalid input. Please type a supported color name in Lower case."
        read line_color
    done

    cat >> /etc/banner.html <<EOF
    <p class="line" style="color: ${line_color:-black}; font-size: ${font_size:-medium}; text-align: ${alignment:-left};">${line_text:- }</p>
EOF
done

cat >> /etc/banner.html <<EOF
</body>
</html>
EOF

echo -e "${GREEN}Banner file created successfully!"

sudo apt update -y && sudo apt upgrade -y

apt-get install -y lsb-release cron iptables ufw apache2 stunnel certbot dropbear squid cmake make gcc build-essential nodejs unzip zip tmux

sudo systemctl stop apache2

sudo certbot certonly --standalone -d $domain_name --non-interactive --agree-tos -m $email_address
$domain_name


mkdir - /etc/stunnel
cd /etc/stunnel
sudo cp /etc/letsencrypt/live/$domain_name/*.pem /etc/stunnel/
openssl rsa -in privkey.pem -out private.key
cat cert.pem fullchain.pem > certificate.crt
cat chain.pem > ca_bundle.crt
cat private.key certificate.crt ca_bundle.crt >stunnel.pem
wget -q https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/stunnel.conf 

cd $HOME
wget -q https://www.dropbox.com/s/a1933zd4h5tcitl/badvpn-master.zip 
unzip -o badvpn-master.zip 
cd badvpn-master 
rm -f build
mkdir build 
cd build 
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 
sudo make install 
cd $HOME 
cd /etc/systemd/system 
wget -q https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/nodews1.service 
cd /etc 
mkdir -p p7common 
cd p7common 
wget -q https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/proxy3.js 
cd $HOME 

cd /etc/systemd/system 
wget -q https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/badvpn.service 
cd $HOME 
sudo rm /etc/shells 
cd /etc/ 
wget -q https://www.dropbox.com/s/leud1a6vdy0d4g7/shells  
cd $HOME 
sudo rm /etc/default/dropbear 
cd /etc/default 
wget -q https://www.dropbox.com/s/u0i3whbaci3mzju/dropbear 
cd $HOME 
systemctl start badvpn 
systemctl start stunnel4 
systemctl start nodews1 
systemctl enable badvpn 
systemctl enable nodews1 
systemctl enable stunnel4 
systemctl status nodews1 
systemctl status badvpn 
systemctl status stunnel4 
systemctl disable apache2 

if id "$user_name" >/dev/null 2>&1; then
    echo "User $user_name already exists. Updating password..."
    echo "$user_name:$pass_word" | chpasswd
    echo "Password updated for user $user_name"
else
    echo "Creating user $user_name with password $pass_word..."
    useradd -M "$user_name" -s /bin/false && echo "$user_name:$pass_word" | chpasswd
    echo "User $user_name created with password $pass_word"
fi
echo -e "\033[0;32mINSTALLATION COMPLETE!!! Please reboot your system\033[0m"
echo -e "\e[33mTotal Time Taken: $SECONDS seconds\e[0m"

