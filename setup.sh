set -ex

apt update
apt install -y python3 wireguard openresolv

cp base/* /etc/wireguard
cd /etc/wireguard

wg genkey | tee wg0.key | wg pubkey > wg0.pub
sed -i "s|<self key here>|$(cat wg0.key)|" $(pwd)/wg0.conf

systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0
