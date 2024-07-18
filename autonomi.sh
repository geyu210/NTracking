#!/usr/bin/env bash

#not used at present
CLIENT=0.92.0
NODE=0.106.5
FAUCET=161.35.173.105:8000
NODE_MANAGER=0.8.0
# get from https://sn-testnet.s3.eu-west-2.amazonaws.com/network-contacts

#run with
# bash <(curl -s https://raw.githubusercontent.com/safenetforum-community/NTracking/main/autonomi.sh)

# first node port can edited in menu later
NODE_PORT_FIRST=12001
NUMBER_NODES=40
DELAY_BETWEEN_NODES=301000

export NEWT_COLORS='
window=,white
border=black,white
textbox=black,white
button=black,white
'

############################################## select test net action

SELECTION=$(whiptail --title "Autonomi Network Beta 2 1.0 " --radiolist \
"Testnet Actions                              " 20 70 10 \
"1" "Install & Start Nodes " OFF \
"2" "Upgrade Client to Latest" OFF \
"3" "Stop Nodes update upgrade & restart system!!  " OFF \
"4" "Spare   " ON \
"5" "Upgrade Nodes" OFF \
"6" "Start Vdash" OFF \
"7" "Remove node owner                        " OFF \
"8" "Add node owner   " OFF 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi

################################################################################################################ start or Upgrade Client & Node to Latest
if [[ "$SELECTION" == "1" ]]; then

Discord_Username=$(whiptail --title "Discord Username" --inputbox "\nEnter Discord Username" 8 40 "timbobjohnes" 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi
if [ -z "${Discord_Username// /}" ]; then
    sleep 0
else
   Discord_Username="--owner $Discord_Username";
fi

NODE_TYPE=$(whiptail --title "Safe Network Testnet   " --radiolist \
"Type of Nodes to start                              " 20 70 10 \
"1" "Node from home no port forwarding    " OFF \
"2" "Cloud based nodes with port forwarding   " ON 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi

#install latest infux resources script from github
sudo rm -f /usr/bin/influx-resources.sh* && sudo wget -P /usr/bin  https://raw.githubusercontent.com/safenetforum-community/NTracking/main/influx-resources.sh && sudo chmod u+x /usr/bin/influx-resources.sh
echo "*/15 * * * * $USER /usr/bin/mkdir -p /tmp/influx-resources && /bin/bash /usr/bin/influx-resources.sh > /tmp/influx-resources/influx-resources" | sudo tee /etc/cron.d/influx_resources

##############################  close fire wall
yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))

NUMBER_NODES=$(whiptail --title "Number of Nodes to start" --inputbox "\nEnter number of nodes" 8 40 $NUMBER_NODES 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi


if [[ "$NODE_TYPE" == "2" ]]; then

NODE_PORT_FIRST=$(whiptail --title "Port Number of first Node" --inputbox "\nEnter Port Number of first Node" 8 40 $NODE_PORT_FIRST 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

############################## disable swap
sudo swapoff -a

############################## open ports
sudo ufw allow $NODE_PORT_FIRST:$(($NODE_PORT_FIRST+$NUMBER_NODES-1))/udp comment 'safe nodes'
sleep 2

fi

############################## Stop Nodes and delete safe folder

yes y | sudo env "PATH=$PATH" safenode-manager reset

# sudo snap remove curl
# sudo apt install curl

# disable installing safe up for every run
#curl -sSL https://raw.githubusercontent.com/maidsafe/safeup/main/install.sh | bash
#source ~/.config/safe/env

rm -rf $HOME/.local/share/safe
rm $HOME/.local/bin/safe
rm /usr/bin/safe

safeup node-manager
safeup client
#--version "$CLIENT"


cargo install vdash

############################## start nodes

mkdir -p /tmp/influx-resources

if [[ "$NODE_TYPE" == "2" ]]; then
# for cloud instances
sudo env "PATH=$PATH" safenode-manager add --node-port "$NODE_PORT_FIRST"-$(($NODE_PORT_FIRST+$NUMBER_NODES-1))  --count "$NUMBER_NODES" $Discord_Username --enable-metrics-server --metrics-port 13001-$((13001+$NUMBER_NODES-1))
else
# for home nodes hole punching
sudo env "PATH=$PATH" safenode-manager add --home-network --count "$NUMBER_NODES" $Discord_Username --enable-metrics-server --metrics-port 13001-$((13001+$NUMBER_NODES-1))
fi

# --version "$NODE"

sudo env "PATH=$PATH" safenode-manager start --interval $DELAY_BETWEEN_NODES | tee /tmp/influx-resources/nodemanager_output & disown

##sudo env "PATH=$PATH" safenode-manager add --node-port "$NODE_PORT_FIRST"-$(($NODE_PORT_FIRST+$NUMBER_NODES-1))  --count "$NUMBER_NODES"  --peer "$PEER"  --url http://safe-logs.ddns.net/safenode.tar.gz


######################################################################################################################## Upgrade Client to Latest
elif [[ "$SELECTION" == "2" ]]; then
############################## Stop client and delete safe folder

rm -rf $HOME/.local/share/safe/client

safeup client

safe wallet get-faucet "$FAUCET"

######################################################################################################################## Stop Nodes
elif [[ "$SELECTION" == "3" ]]; then

sudo pkill -e safe

# stop nodes
# nuke safe node manager services 1 - 100 untill nuke comand exists

for i in {1..500}
do
 # your-unix-command-here
 sudo systemctl disable --now safenode$i
done

sudo rm /etc/systemd/system/safenode*
sudo systemctl daemon-reload

sudo rm -rf /var/safenode-manager
sudo rm -rf /var/log/safenode

rm -rf $HOME/.local/share/safe/node

sleep 2

############################## close fire wall

yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))
yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))
yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))

#close fire wall ports
for i in {1..60}
do
sudo ufw delete allow $((12000+$i))/udp
done

rm /tmp/influx-resources/nodemanager_output.lock

rustup update
sudo apt update -y && sudo apt upgrade -y
sudo reboot


######################################################################################################################## spare
elif [[ "$SELECTION" == "4" ]]; then

echo "spare 4"

######################################################################################################################### Upgrade Nodes
elif [[ "$SELECTION" == "5" ]]; then

sudo env "PATH=$PATH" safenode-manager upgrade --interval 60000  | tee -a /tmp/influx-resources/node_upgrade_report

######################################################################################################################### Start Vdash
elif [[ "$SELECTION" == "6" ]]; then
vdash --glob-path "/var/log/safenode/safenode*/safenode.log"
######################################################################################################################### remove owner from nodes
elif [[ "$SELECTION" == "7" ]]; then

# Verzeichnis mit den Service-Dateien
SERVICE_DIR="/etc/systemd/system"

# Suche alle Dateien, die mit 'safenode' beginnen
for service_file in $SERVICE_DIR/safenode*.service; do
    if [ -f "$service_file" ]; then
        # Entferne das --owner Flag aus der ExecStart Zeile
        sed -i 's/--owner \S*//' "$service_file"
        echo "Updated $service_file"
    fi
done

# Neu laden der Systemd-Unit-Dateien
systemctl daemon-reload

# Suche alle laufenden Services, die mit 'safenode' beginnen und starte sie neu
for service in $(systemctl list-units --type=service --state=running | grep 'safenode' | awk '{print $1}'); do
    systemctl restart "$service"
    echo "Restarted $service"
done

######################################################################################################################### add user back to nodes
elif [[ "$SELECTION" == "8" ]]; then

Discord_Username=$(whiptail --title "Discord Username" --inputbox "\nEnter Discord Username" 8 40 "timbobjohnes" 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

# Besitzer-Parameter
OWNER=$Discord_Username

# Directory containing the service files
SERVICE_DIR="/etc/systemd/system"

# Search for all files starting with 'safenode'
for service_file in $SERVICE_DIR/safenode*.service; do
    if [ -f "$service_file" ]; then
        # Check if the --owner parameter is already present
        if ! grep -q '--owner' "$service_file"; then
            # Add the --owner parameter to the ExecStart line
            sed -i "s|\(ExecStart=.*\)|\1 --owner $OWNER|" "$service_file"
            echo "Updated $service_file with owner $OWNER"
        fi
    fi
done

# Reload the systemd unit files
systemctl daemon-reload

# Search for all running services starting with 'safenode' and restart them
for service in $(systemctl list-units --type=service --state=running | grep 'safenode' | awk '{print $1}'); do
    systemctl restart "$service"
    echo "Restarted $service"
done

fi
