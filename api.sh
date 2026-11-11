clear
green="\e[38;5;82m"
red="\e[38;5;196m"
neutral="\e[0m"
orange="\e[38;5;130m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
purple="\e[38;5;141m"
bold_white="\e[1;37m"
reset="\e[0m"
print_header() {
echo -e "${green}⚡ API-ARI :: [API SYSTEM]${neutral}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}"
echo -e "   ⚙️ ${bold_white}Secure${neutral} | ${green}Fast${neutral} | ${purple}Stable${neutral}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${neutral}\n"
}
print_rainbow() {
local text="$1"
for ((i=0;i<${#text};i++)); do
printf "\e[38;5;$((RANDOM%200+20))m${text:$i:1}"
done
echo -e "$reset"
}
cek_status() {
if systemctl is-active --quiet "$1"; then
echo -e "${green}ONLINE${neutral}"
else
echo -e "${red}OFFLINE${neutral}"
fi
}
setup_bot() {
print_header
print_rainbow "�� Initializing Setup..."
rm -rf /usr/bin/api-lite >/dev/null 2>&1
rm -f /usr/bin/api-lite.zip
NODE_VERSION=$(node -v 2>/dev/null | grep -oP '(?<=v)\d+' || echo "0")
rm -f /var/lib/dpkg/stato* /var/lib/dpkg/lock*
if [ "$NODE_VERSION" -lt 22 ]; then
echo -e "${yellow}Install Node.js v22...${neutral}"
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install -g npm@latest
else
echo -e "${green}Node.js v$NODE_VERSION OK${neutral}"
fi
if [ ! -f /usr/bin/api-ari/api.js ]; then
echo -e "${blue}Download API-ARI...${neutral}"
curl -sL "https://raw.githubusercontent.com/dex827191/api-ari/main/api-ari.zip" -o /usr/bin/api-ari.zip
cd /usr/bin
unzip api-ari.zip >/dev/null 2>&1
rm api-ari.zip*
chmod +x api-ari/*
cd
fi
npm list --prefix /usr/bin/api-ari express child_process >/dev/null 2>&1 || \
npm install --prefix /usr/bin/api-ari express child_process
NEW_AUTH_KEY=$(openssl rand -hex 3)
sed -i '/export AUTH_KEY=/d' /etc/profile
echo "export AUTH_KEY=\"$NEW_AUTH_KEY\"" >> /etc/profile
source /etc/profile >/dev/null 2>&1
SERVER_IP=$(curl -s ipv4.icanhazip.com)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "No Domain")
echo -e "${green}Telegram tidak diperlukan.${neutral}"
echo -e "${blue}Informasi instalasi akan ditampilkan langsung di VPS.${neutral}"
echo -e "\n${green}�� API-ARI Installed${neutral}"
echo -e "🔑 Auth: ${bold_white}$AUTH_KEY${neutral}"
echo -e "🌐 IP: ${bold_white}$SERVER_IP${neutral}"
echo -e "🌍 Domain: ${bold_white}$DOMAIN${neutral}"
echo -e "${green}Setup selesai!${neutral}"
}
server_app() {
print_rainbow "⚙️ Setup Service..."
systemctl stop apisellvpn.service >/dev/null 2>&1
systemctl disable apisellvpn.service >/dev/null 2>&1
rm -f /etc/systemd/system/apisellvpn.service
cat > /etc/systemd/system/apisellvpn.service <<EOF
[Unit]
Description=API ARI Service
After=network.target
[Service]
ExecStart=/bin/bash /usr/bin/apisellvpn
Restart=always
User=root
WorkingDirectory=/usr/bin
[Install]
WantedBy=multi-user.target
EOF
cat > /usr/bin/apisellvpn <<EOF
source /etc/profile
cd /usr/bin/api-ari
node api.js
EOF
chmod +x /usr/bin/apisellvpn
CEK_PORT=$(lsof -i:5889 | awk 'NR>1 {print $2}' | sort -u)
if [[ -n "$CEK_PORT" ]]; then
echo "Kill port 5889..."
echo "$CEK_PORT" | xargs kill -9
fi
systemctl daemon-reload
systemctl enable apisellvpn.service
systemctl restart apisellvpn.service
echo -e "Status: $(cek_status apisellvpn.service)"
}
setup_bot
server_app
