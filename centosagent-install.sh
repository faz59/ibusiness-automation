#!/bin/sh
# agent-install.sh
# Copyright 2005-2015 Cirrus Parsa.

#usage bash ./agent-install.sh patchy shanzi  test ./agent-install.sh vbox
# $1 [prefix eg xxx for xxx.parsa.me.uk]
# $2 [puppet master prefix eg nsxx for nsxx.parsa.me.uk]

#/*
#hostnamectl set-hostname patchy.parsa.me.uk
#systemctl restart systemd-hostnamed
#*/

#0. New server, set fqdn, ip to /etc/hosts and assign server number and root password


thisServer=$1
masterServer=$2



if [[ "$thisServer" == "--help" ] || [ "$thisServer" == "-h" ]] ;  then
  echo "Primary installer for Centos, LAMP, Virtualbox and ready for puppet communication.\nUsage: xxxxagent-install.sh agentServer masterServer\n .parsa.me.uk will be added automatically. "
  exit;
fi  

#to-do check to make sure two params are entered!


#if [[ "$thisServer" == "vbox" ]] ;  then
#  echo "Installing on a virtual box for testing..."
#else
  #to-do find how to include param $1 in quoted text
  echo "Installing on a $1.parsa.me.uk with master in $masterServer.parsa.me.uk ..."
#fi

#1. pre-requisite install

cd /home
yum -y update
yum -y install nano ntp ntpdate ntp-doc perl  git
#change centos to   uk   /etc/ntp.conf
sed -i 's/centos/uk/g' /etc/ntp.conf 
chkconfig ntpd on
#to-do add to cron every 10 mintes  ???

service ntpd restart

#if [[ "$thisServer" == "vbox" ]] ;  then
  #special for virtualbox only when no fqdn exists
#  echo "192.168.1.94 puppetmaster.localhost"   >>/etc/hosts
#  systemctl restart systemd-hostnamed
#fi

#2. puppet 
firewall-cmd --zone=public --permanent   --add-port=8140/tcp
service firewalld restart
setenforce permissive
sed -i 's/Enforcing/Permissive/g' /etc/selinux/config 
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
yum -y install puppet

#if [[ "$thisServer" == "vbox" ]] ;  then  
#special for virtualbox only where no fqdn exists
#  echo "server = puppetmaster.localhost">> /etc/puppet/puppet.conf
#else  
#  echo "server = $masterServer.parsa.me.uk" >> /etc/puppet/puppet.conf
#fi

chkconfig puppet on
puppet resource package puppet ensure=latest
puppet agent --verbose --no-daemonize --onetime  
#to-do change request interval also  make above non-interactive

read -rsp $'Puppet installed finished, ctrl-C to stop or any key to continue. ---- \n' -n1 key
#3. virtualmin
cd /root
bash ./virtualmin-install.sh -f

chkconfig webmin on
service webmin restart
chkconfig postgresql off
chkconfig mailman off
service postgresql stop
service mailman stop
#send an email to admin
reboot


#4. https://ip-addr:10000
# virtualmin : features, virtualmin configuration, server template has to be done manually
#mysqladmin grant all privileges on *.* to root@localhost identified by 'to-do root password'
# puppet to handle service :  apache, bind , mysql , dovecot , postfix , spamassasin , clamav 
# puppet to handle config  :  virtualmin (apache, bind) , apache, bind, mysql, dovecot, postfix , spamassasin, clamav 
# puppet to handle ibizProduction : Transfer production system
# puppet to handle ibizSites : run command to initialize ibiz site - add to master bind
# advance puppet to handle move (emails, mysql db) and change master dns
# create v6.parsa.me.uk site for master repo 


#On master server
#sign this servers certificate in puppetmaster and the rest goes via puppet comms





