#!/bin/bash

# Install Elastic Stack
# Author: Graeme Meyer (@GraemeMeyer)

# Exit if not root user / sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or the sudo user." 
  exit
fi


# Install Java 8 (OpenJDK)
# TODO: Upgrade to Java 11 or 14. Official, non-JDK?
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
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service

# Stop and then start the Elasticsearch service
sudo systemctl stop elasticsearch.service
sudo systemctl start elasticsearch.service

# Test if Elasticseach is working
if curl 'localhost:9200/?pretty'
then echo "yes"
else echo "no"; exit;
fi


# Set the Kibana repository
cat <<EOF | sudo tee /etc/yum.repos.d/kibana.repo
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Install Kibana from the RPM repository
sudo dnf install -y kibana

# Configure Kibana
KIBANA_REPLACETEXT='server.host:'
KIBANA_NEW='server.host: "0.0.0.0"'
sed -i "/$KIBANA_REPLACETEXT/c $KIBANA_NEW" /etc/kibana/kibana.yml

# Configure Kibana to start when the system boots
sudo systemctl daemon-reload
sudo systemctl enable kibana.service

# Stop and then start the Kibana service
sudo systemctl stop kibana.service
sudo systemctl start kibana.service

# Test if Kibana is online
for i in {1..10}
do  
    if curl 'localhost:5601'
    then 
        $KibanaWorking = "yes"
        echo "Kibana up."
        break
    else 
        $KibanaWorking = "no"
        echo "Kibana down."
        sleep 5s
    fi

    if $i -eq "5"
    then
    echo "Kibana never came up."
    echo "Exiting"
    exit
    fi
done


# Edit system resource limits in Elasticsearch
if [[ -e /etc/sysconfig/elasticsearch ]]; then
	sed -i '/MAX_LOCKED_MEMORY/s/^#//g' /etc/sysconfig/elasticsearch
elif [[ -e /etc/default/elasticsearch ]]; then
	sed -i '/MAX_LOCKED_MEMORY/s/^#//g' /etc/default/elasticsearch
fi

# Limit memory by setting Elasticsearch heap size (use no more than half of your available memory and 32gb max)
heap_size="1g"
sed -i "s/^-Xms.*$/-Xms${heap_size}/" /etc/elasticsearch/jvm.options
sed -i "s/^-Xmx.*$/-Xmx${heap_size}/" /etc/elasticsearch/jvm.options

systemctl daemon-reload
service elasticsearch restart
service kibana restart


# Set the Logstash repository
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat <<EOF | sudo tee /etc/yum.repos.d/logstash.repo
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Install Logstash from the RPM repository
sudo yum install -y logstash