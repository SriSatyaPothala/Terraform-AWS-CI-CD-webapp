#!/bin/bash

apt update -y
apt install -y docker.io ruby-full wget unzip awscli

#add the ubuntu user to the docker group
usermod -aG docker ubuntu

systemctl start docker
systemctl enable docker

cd /home/ubuntu

# Install CodeDeploy Agent
wget https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/install
chmod +x ./install
./install auto

systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
