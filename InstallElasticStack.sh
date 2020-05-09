#!/bin/bash

# Install Elastic Stack
# Author: Graeme Meyer (@GraemeMeyer)

# Install Java 8 (OpenJDK)
dnf -y install java-1.8.0-openjdk-devel.x86_64 java-1.8.0-openjdk.x86_64

# Import the Elasticsearch PGP Key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Set the Elasticsearch repository
cat <<EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF

# Install Elasticsearch
sudo dnf install -y --enablerepo=elasticsearch elasticsearch

# Configure Elasticsearch to start when the system boots
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

# Stop and then start the Elasticsearch service
sudo systemctl stop elasticsearch.service
sudo systemctl start elasticsearch.service

# Test if Elasticseach is working
if curl 'localhost:9200/?pretty'
then echo "yes"
else echo "no"; break;
fi

# Install Kibana from the RPM repository
sudo dnf install -y kibana

# Configure Kibana to start when the system boots
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service

# Stop and then start the Kibana service
sudo systemctl stop kibana.service
sudo systemctl start kibana.service