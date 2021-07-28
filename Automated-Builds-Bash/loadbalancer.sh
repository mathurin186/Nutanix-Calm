#!/bin/bash
set -ex

yum update -y
yum install -y haproxy

#!/bin/bash
set -ex
echo "global
  log 127.0.0.1 local0
  log 127.0.0.1 local1 notice
  maxconn 4096
  quiet
  user haproxy
  group haproxy

defaults
  log     global
  mode    http
  retries 3
  timeout client 50s
  timeout connect 5s
  timeout server 50s
  option dontlognull
  option httplog
  option redispatch
  balance  roundrobin

# Set up application listeners here.

listen admin
  bind 127.0.0.1:22002
  mode http
  stats uri /


frontend http
  maxconn 2000
  bind 0.0.0.0:80
  default_backend servers-http


backend servers-http" | tee /etc/haproxy/haproxy.cfg

hosts=$(echo "@@{App01Service.address}@@,@@{App02Service.address}@@" | tr "," "\n")

port=80
for host in $hosts
do
   echo "  server host-${host} ${host}:${port} weight 1 maxconn 100 check" | tee -a /etc/haproxy/haproxy.cfg
done

systemctl daemon-reload
systemctl restart haproxy

firewall-cmd --add-service=http --zone=public --permanent
firewall-cmd --reload

