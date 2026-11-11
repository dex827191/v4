set -e
apt update -y
apt install -y git
cd /root
rm -rf noobzvpns
export GIT_TERMINAL_PROMPT=0
git clone https://github.com/noobz-id/noobzvpns.git
cd noobzvpns
chmod +x install.sh
bash install.sh
