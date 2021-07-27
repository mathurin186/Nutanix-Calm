#!/bin/bash

sudo yum update -y

sudo yum install wget -y

sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

sudo yum install jenkins java-11-openjdk-devel -y

sudo systemctl daemon-reload

sudo systemctl start jenkins

sudo systemctl status jenkins

sleep 5s

cat /var/lib/jenkins/secrets/initialAdminPassword > password.txt

var1=$(cat /var/lib/jenkins/secrets/initialAdminPassword)

echo ""
echo ""
echo "================================================================"
echo "====================  Initial Password  ========================"
echo "================================================================"
echo "${var1} "
echo "================================================================"