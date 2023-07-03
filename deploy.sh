set -e

terraform init
terraform apply

ssh_dir=$(pwd)/.secret
server_ip=$(terraform output -raw wg_eip)

cp $(pwd)/base/routing.info $(pwd)/base/routing.info.bak
sed -i "s/0.0.0.0/$server_ip/g" $(pwd)/base/routing.info
tar -czf wg-kit.tar.gz base/ wg_addpeer.py setup.sh
mv $(pwd)/base/routing.info.bak $(pwd)/base/routing.info

scp -i $ssh_dir/wg-kit_key.pem $(pwd)/wg-kit.tar.gz ubuntu@$server_ip:wg-kit.tar.gz
ssh -i $ssh_dir/wg-kit_key.pem ubuntu@$server_ip "tar -xzf wg-kit.tar.gz && chmod +x setup.sh && sudo ./setup.sh"
