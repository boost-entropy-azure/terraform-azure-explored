apt-get update
apt-get install -y ngnix
echo $(hostname) | sudo tee /var/www/html/index.html