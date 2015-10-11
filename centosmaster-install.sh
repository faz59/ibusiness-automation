#!/bin/sh
# agent-install.sh
# Copyright 2005-2015 Cirrus Parsa.

#usage bash ./centosmaster-install.sh ns23    ./centosmaster-install.sh vbox
# $1 [puppet master prefix eg nsxx for nsxx.my-ibusiness.com]


#0. New server, set fqdn, ip to /etc/hosts and assign server number and root password
#download centosmaster-install.sh  virtualmin-install.sh puppetmaster.conf



masterServer=$1

if [[ "$thisServer" == "--help" ]] ;  then
  echo "Primary installer for Centos, LAMP, Virtualbox and ready for puppet setup.\nUsage: xxxxmaster-install.sh masterServer\n .my-ibusiness.com will be added automatically. "
  exit;
fi  

if [[ "$thisServer" == "vbox" ]] ;  then
  echo "Installing on a virtual box for testing..."
else
  echo "Installing on a $masterServer.my-ibusiness.com with master in $masterServer.my-ibusiness.com ..."
fi

#1. pre-requisite install

cd /home
#yum -y update
yum -y install nano ntp ntpdate ntp-doc perl  git
#change centos to   uk   /etc/ntp.conf
sed -i 's/centos/uk/g' /etc/ntp.conf 
chkconfig ntpd on
#to-do add to cron every 10 mintes  ???
service ntpd restart

read -rsp $'Initial packages installed. ---- \n' -n1 key

#hostnamectl set-hostname ns36.my-ibusiness.com
#systemctl restart systemd-hostnamed

#if [[ "$thisServer" == "vbox" ]] ;  then
  #special for virtualbox only when no fqdn exists
  #echo "192.168.1.94 puppetmaster.localhost"   >>/etc/hosts
#  systemctl restart systemd-hostnamed
#fi

#2. puppet 
firewall-cmd --zone=public --permanent   --add-port=8140/tcp
service firewalld restart
setenforce permissive
sed -i 's/Enforcing/Permissive/g' /etc/selinux/config 
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
yum -y install puppet-server
mkdir -p /etc/puppet/environments/production/{modules,manifests}
#to-do make once only
echo "modulepath=/etc/puppet/environments/production/modules 
      environment_timeout =5s " >>/etc/puppet/environments/production/environment.conf   


#/* #to-do /etc/puppet/puppet.conf
#"dns_alt_name=puppetmaster.my-ibusiness.com"
#*/
#to-do make once only
echo "[master] 
   environmentpath = $confdir/environments 
   basemodulepath = $confdir/modules:/opt/puppet/share/modules" >> /etc/puppet/puppet.conf

read -rsp $'Puppet packages installed. ---- \n' -n1 key

#chkconfig puppet on
#puppet resource package puppet ensure=latest
puppet master --verbose --no-daemonize --onetime 


read -rsp $'Puppet ssl generated. ---- \n' -n1 key



yum -y install httpd httpd-devel mod_ssl ruby-devel rubygems gcc gcc-c++ libcurl-devel openssl-devel
gem install rack passenger
#manual process passenger-install-apache2-module   #to-do check -f param  copy setting for httpd.conf
mkdir -p /usr/share/puppet/rack/puppetmasterd/public
mkdir -p /usr/share/puppet/rack/puppetmasterd/tmp
cp  /usr/share/puppet/ext/rack/config.ru /usr/share/puppet/rack/puppetmasterd/
chown puppet:puppet /usr/share/puppet/rack/puppetmasterd/config.ru



#to-do does not owrk with variable sed -i 's/puppetmaster.localdomain/'+$masterServer+'/g' puppetmaster.conf 
cp puppetmaster.conf /etc/httpd/conf.d/puppetmaster.conf        #to-do change the ssl key parameter first to this server
#service httpd restart

passenger-install-apache2-module 
read -rsp $'Puppet configured. ---- \n' -n1 key


#3. virtualmin
cd /home
bash ./virtualmin-install.sh -f


read -rsp $'virtualmin packages installed. ---- \n' -n1 key


chkconfig webmin on
service webmin restart
chkconfig postgresql off
chkconfig mailman off
service postgresql stop
service mailman stop

read -rsp $'virtualmin clean ups done. ---- \n' -n1 key


#this requires manual input, so leave it to the last


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
# create v6.my-ibusiness.com site for master repo 


#On master server
#sign this servers certificate in puppetmaster and the rest goes via puppet comms





