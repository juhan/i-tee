# About i-tee
i-tee is a distance laboratory system, that is based on ruby on rails and uses VirtualBox headless virtualization.

i-tee is developed by the Estonian IT College.

More information about i-tee and one lab (we call them a learningspace) can be found from following article:
http://conferences.sigcomm.org/sigcomm/2015/pdf/papers/p113.pdf


    Margus Ernits, Johannes Tammekänd, and Olaf Maennel. 2015. 
    i-tee: A fully automated Cyber Defense Competition for Students. 
    In Proceedings of the 2015 ACM Conference on Special Interest Group on Data Communication (SIGCOMM '15). 
    ACM, New York, NY, USA, 113-114. DOI=http://dx.doi.org/10.1145/2785956.2790033


i-tee contains three layers such as: Virtualisation, Web frontend (access control, lab control), Learningspace layer.

# Preparing for installation of i-tee

Before installing i-tee system the Ubuntu server with VirtualBox headless is needed.


* Install Ubuntu Server 14.04 LTS 64bit with separate /var directory (enough room for virtual machines)
* Choose btrfs filesystem for /var for virtual machines (optional)
* Configure network

Do system upgrade and install additional packages

	sudo apt-get update

	sudo apt-get dist-upgrade

	sudo apt-get install linux-headers-$(uname -r) build-essential dkms

	sudo apt-get install unzip git htop -y
	
	sudo apt-get install makepasswd -y


# Installing virtualization layer

For virtualization layer the VirtualBox headless mode is used with phpVirtualBox web interface.


## Installing VirtualBox headless

VirtualBox headless installation guide is based on [HowtoForge - Linux Tutorials](http://www.howtoforge.com) article:
[VBoxHeadless - Running Virtual Machines With VirtualBox 4.3 On A Headless Ubuntu 14.04 LTS Server - Author: Falko Timme, updated by Srijan Kishore](http://www.howtoforge.com/vboxheadless-running-virtual-machines-with-virtualbox-4.3-on-a-headless-ubuntu-14.04-lts-server)

All commands followed must be entered as a root user. To get interactive root shell:

	sudo -i
	
Add virtualbox apt source to software sources list:

	echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" \
	 > /etc/apt/sources.list.d/virtualbox.list

Download and import Oracle VirtualBox public key:

	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc \
	 -O- | sudo apt-key add -

Upgrade local repository cache:
	
	apt-get update

Install VirtualBox 5.0 package:

	apt-get install virtualbox-5.0 -y
	
In case of upgrade, remove vbox extension back

	VBoxManage extpack uninstall "Oracle VM VirtualBox Extension Pack"
	su - vbox -c'vboxmanage extpack uninstall "Oracle VM VirtualBox Extension Pack"'

If everything is successful then module list should contain vboxdrv module. Test it using lsmod:
	
	lsmod |grep vboxdrv

The result should look like:

vboxdrv               409815  3 vboxnetadp,vboxnetflt,vboxpci


Download and install VirtualBox Extension Pack that corresponds to your version of VirtualBox.
First find out virtualbox version:

	VER=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d-|cut -f2 -d' ')

Seconly find out subversion of virtualbox:

	SUBVER=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d~|cut -f2 -d' ')

Test results:

	echo $VER
	echo $SUBVER


Install particular extension pack

	wget http://download.virtualbox.org/virtualbox/${VER}/Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack

Install the extension pack using vboxmanage:

	VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack

List extension packs using vboxmanage:

	VBoxManage list extpacks

The result should contain
	
	Oracle VM VirtualBox Extension Pack

Create user ***vbox*** for virtualbox with strong password:

	adduser vbox

Add user ***vbox*** to group ***vboxusers***:

	adduser vbox vboxusers

Change ***vbox*** user home directory to ***/var/labs*** and move dotfiles into it:

	usermod -d /var/labs -m vbox


### Creating autostart files and configuring vbox user
To create complete virtual laboratory environment you need DNS server for fake zones, DHCP server for lab VMs and probably firewall for filtering.
For some VMs such as nameserver, DHCP server, Firewall etc the autostart is needed.

```
cat > /etc/default/virtualbox << EOF
VBOXWEB_USER=vbox
VBOXAUTOSTART_DB=/etc/vbox
VBOXAUTOSTART_CONFIG=/etc/vbox/auto.cfg
EOF
```

```
cat > /etc/vbox/auto.cfg << EOF
default_policy = deny
vbox = {
        allow = true
        startup_delay = 10
}
EOF
```

Enable autostartpath

	su - vbox -c'VBoxManage setproperty autostartdbpath /etc/vbox'
	chgrp vboxusers /etc/vbox
	

## Installing phpVirtualBox 

Ensure that user ***vbox*** is configured as ***VBOXWEB_USER***

	grep vbox /etc/default/virtualbox

Enable ***vboxweb service*** autostart:

	update-rc.d vboxweb-service defaults
	service vboxweb-service start

### Installing nginx web server with php

Install ***nginx*** web server:

	sudo apt-get install nginx

Create new virtualhost ***i-tee***

We setup separate virtualhost for managing interface (phpVirtualBox) and the lab web application (ports: 4433 for phpVirtualbox and 443 for i-tee web app)

Make sure that you have FQDN for your website.
Generate SSL key for phpVirtualBox virtualhost

	ssh-keygen -f /etc/ssl/private/YOUR-FQDN.key

Press enter twice if you do not want passpharse for key.


Generate certificate request


	openssl req -new -key /etc/ssl/private/YOUR-FQDN.key \
		 -out /root/YOUR-FQDN.req


Country Name (2 letter code) [AU]: < -- Enter Country Code (example EE)

State or Province Name (full name) [Some-State]: < -- Enter your state name (example Harjumaa)

Locality Name (eg, city) []: < -- Enter City Name (example Tallinn)

Organization Name (eg, company) [Internet Widgits Pty Ltd]: < -- Enter Organization name (example Estonian IT College)

Organizational Unit Name (eg, section) []: < -- Hit enter

Common Name (e.g. server FQDN or YOUR name) []: < -- YOUR-FQDN (example i-tee.itcollege.ee)

Email Address []:< -- Hit enter

A challenge password []:< -- Hit enter

An optional company name []:< -- Hit enter


To check certificate data:
	
	openssl req -in /root/YOUR-FQDN.req -text -noout

Use CA to sign certificate or self signed cert in case of test environment only


NB for testing only 

	openssl x509 -req -days 3650 -in /root/YOUR-FQDN.req -signkey /etc/ssl/private/YOUR-FQDN.key -out  /etc/ssl/certs/YOUR-FQDN.pem

After signing sertificate please copy signed cert into /etc/ssl/certs/
For example open certificate file /etc/ssl/certs/YOUR-FQDN.pem and copy signed cert into this file.

To check signed certificate data:

	openssl x509 -in /etc/ssl/certs/YOUR-FQDN.pem -text -noout


Download latest version of phpVirtualBox http://sourceforge.net/projects/phpvirtualbox/files/?source=navbar
VirtualBox and phpVirtualBox versions must match. For example, for VirtualBox-4.3 series you need phpvirtualbox-4.3-x.zip:

		
	PHPVIRTUALBOX=5.0-3.zip
	
	wget https://github.com/imoore76/phpvirtualbox/archive/$PHPVIRTUALBOX -O $PHPVIRTUALBOX
	
	unzip $PHPVIRTUALBOX
	
	cp -a /root/phpvirtualbox-$(basename $PHPVIRTUALBOX .zip) /usr/share/nginx/
	
	ln -sf /usr/share/nginx/phpvirtualbox-$(basename $PHPVIRTUALBOX .zip) /usr/share/nginx/phpvirtualbox
	
	chown www-data:www-data /usr/share/nginx/phpvirtualbox -R



Create new virtualhost for phpVirtualBox

	cat > /etc/nginx/sites-available/i-tee << EOF
	# HTTPS server
	#
	server {
		listen 4433;
	
		root /usr/share/nginx/phpvirtualbox;
		index index.php index.html index.htm;
	
		ssl on;
		ssl_certificate /etc/ssl/certs/YOUR-FQDN.pem;
		ssl_certificate_key /etc/ssl/private/YOUR-FQDN.key;
	
		ssl_session_timeout 5m;
	
		ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
		ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
		ssl_prefer_server_ciphers on;
	
		location / {
				try_files \$uri \$uri/ /index.html;
		}
		location ~ \.php$ {
			   fastcgi_split_path_info ^(.+\.php)(/.+)$;
			   # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
			   fastcgi_pass unix:/var/run/php5-fpm.sock;
			   fastcgi_index index.php;
			   include fastcgi_params;
		}
	
	
		location ~ /\.ht {
				deny all;
		}
	
	}
	EOF


Install php support for nginx

	apt-get install php5-fpm

Enable virtualhost i-tee

	ln -s /etc/nginx/sites-available/i-tee /etc/nginx/sites-enabled/

Disable default website
	
	 rm /etc/nginx/sites-enabled/default

Restart nginx web server

	service nginx restart



Change vbox user password to the same vbox system user
	
	cp /usr/share/nginx/phpvirtualbox/config.php-example \
	/usr/share/nginx/phpvirtualbox/config.php

	vim /usr/share/nginx/phpvirtualbox/config.php


Configure virtualbox RDP authenticaton

	su - vbox -c'VBoxManage setproperty vrdeauthlibrary "VBoxAuthSimple"'

Log in into vbox interface https://YOUR-FQDN:4433 and change admin's password. Default is admin


# Application Config
Configuration files are needed as following with sample files included:

- config/environments/development.rb
- config/environments/production.rb
- config/environments/test.rb
- config/ldap.yml
- config/database.yml


# Installation of i-tee

Make sure that virtualization layer works and VMs can be created using phpVboxManage interface.


Make yourself the root user

	sudo -i
	
	
You need ruby 2 to run i-tee

	apt-get install -y python-software-properties
	apt-add-repository ppa:brightbox/ruby-ng
	apt-get update
	apt-get install -y ruby2.2 ruby2.2-dev ruby-switch
	ruby-switch --set ruby2.2 ruby2.2-dev
	apt-get install git-core curl zlib1g-dev 
	apt-get install libssl-dev libreadline-dev 
	apt-get install libyaml-dev libsqlite3-dev sqlite3 libxml2-dev 
	apt-get install libxslt1-dev libcurl4-openssl-dev 

Do we need python-software-properties?


Check the version of ruby and rails installed:

	ruby -v
	ruby 2.2.2p95 (2015-04-13 revision 50295) [x86_64-linux]


	gem -v
	2.4.5


## installing the distance laboratory system

Create the railsapps directory

	mkdir -p /var/www/railsapps/

Create directory for runtime files

	mkdir -p /var/labs/run/
	chown vbox.www-data /var/labs/run/
	chmod g+w /var/labs/run/
    chmod g+s /var/labs/run/

Download the code from GitHub to the newly created folder

	cd /var/www/railsapps
	git clone git://github.com/magavdraakon/i-tee.git

Go to the project folder

	cd i-tee


For the database use mysql server.

	apt-get install libmysqlclient-dev mysql-server

run the mysql client under root

	mysql -p

Creating the user for the database:

	create database itee_production character set utf8;
	create user 'itee'@'localhost' identified by 's0mestrongpassw0rd<- CHANGETHISPASSWORD!';
	grant all privileges on itee_production.* to 'itee'@'localhost';
	quit;

Create new file config/database.yml for database credentials with following content:

	#vim|nano config/database.yml
	production:
	        adapter: mysql
	        database: itee_production
	        username: itee
	        password: s0mestrongpassw0rd <- CHANGETHISPASSWORD!


Getting the production config

	cp config/environments/production_sample.rb config/environments/production.rb 

Ensure that emulate_virtualization is set to false

	config.emulate_virtualization = false
	config.emulate_ldap = false

Enter admin usernames

	#Administrator usernames
	config.admins = ['admin1','admin2','admin3','etc']

Create the LDAP config

	cp config/ldap_sample.yml config/ldap.yml 

And change the info according to your own LDAP server settings

	production:
	  host: yourhost
	  port: 636
	  attribute: cn
	  base: ou=people,dc=test,dc=com
	  admin_user: cn=admin,dc=test,dc=com
	  admin_password: admin_password
	  ssl: true

And change information about group_base:



## Gems, database migration

Install bundler

	apt-get install bundler

Install gems

	bundle install

Now migrate the database

	rake db:migrate RAILS_ENV="production"

Add default data to the tables

	rake db:seed RAILS_ENV="production" 


## installing passenger

install passenger for hosting Rails applications 

	gem install passenger

Install the required software:

Curl development headers with SSL support

	apt-get install libcurl4-openssl-dev

OpenSSL development headers

	apt-get install libssl-dev
  
Apache 2 web server

	apt-get install apache2

Apache 2 development headers

	apt-get install apache2-prefork-dev

Apache Portable Runtime (APR) development headers

	apt-get install libapr1-dev

Apache Portable Runtime Utility (APU) development headers

	apt-get install libaprutil1-dev

And run the installer

	passenger-install-apache2-module

Create new configuration files to enable passenger

	/etc/apache2/mods-available/passenger.load
	/etc/apache2/mods-available/passenger.conf

NB! the following lines are given to you during passenger installation

insert the similar line into the .load file

	LoadModule passenger_module /usr/lib/ruby/gems/CHANGEVERSION/gems/passenger-CHANGEVERSION/ext/apache2/mod_passenger.so

For example:
	LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-4.0.53/buildout/apache2/mod_passenger.so


insert the similar lines into the .conf file

```
<IfModule mod_passenger.c>
    PassengerRoot /usr/lib/ruby/gems/CHANGEVERSION/gems/passenger-<version>
    PassengerRuby /usr/bin/rubyCHANGEVERSION
</IfModule>
```

For example:
```
<IfModule mod_passenger.c>
PassengerRoot /var/lib/gems/1.9.1/gems/passenger-4.0.53
PassengerDefaultRuby /usr/bin/ruby1.9.1
</IfModule>
```
execute these commands to enable passenger and restart the apache server

	a2enmod passenger

	service apache2 restart


Create a file 

	/etc/apache2/sites-available/itee.conf

And insert the following lines

```
   <VirtualHost *:80>
      ServerName www.yourhost.com
      # !!! Be sure to point DocumentRoot to 'public'!
      DocumentRoot /var/www/railsapps/i-tee/public
      RewriteEngine On
      RewriteCond %{HTTPS} off
      RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
      ErrorLog /var/log/apache2/error-itee.log
      LogLevel warn
      CustomLog /var/log/apache2/access-itee.log combined
      <Directory /var/www/railsapps/i-tee/public>
         # This relaxes Apache security settings.
         AllowOverride all
         # MultiViews must be turned off.
         Options -MultiViews
         # Uncomment this if you're on Apache >= 2.4:
         Require all granted
      </Directory>
   </VirtualHost>


  <VirtualHost *:443>
    ServerName <server (ie: project.itcollege.ee)>
    DocumentRoot /var/www/railsapps/i-tee/public
    ErrorLog /var/log/apache2/error-itee.log
    LogLevel warn
    CustomLog /var/log/apache2/access-itee.log combined
    SSLEngine on
    SSLProtocol All -SSLv2 -SSLv3
    SSLCertificateFile /etc/apache2/project.pem
    SSLCertificateKeyFile /etc/apache2/project.key
    SSLOptions +StdEnvVars
  </VirtualHost>
```

Enable ssl, headers and rewrite modules

	a2enmod ssl rewrite headers

and enable the new site

	a2ensite itee

Disable the default site
	
	a2dissite 000-default.conf


reload the web servers configuration files

	service apache2 reload



VirualBox permissions
User vbox (group vboxusers)
	
	adduser www-data vboxusers

Change owner for /var/www directory

	chown www-data:www-data /var/www -R

```
cat >/etc/sudoers.d/itee<<END
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/start_machine.sh 
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/stop_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/resume_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/pause_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/delete_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/reset_vbox_rdp.sh
www-data ALL=(vbox) NOPASSWD: /usr/bin/VBoxManage
END
```


	chmod 0440 /etc/sudoers.d/itee	

Make config directory for virtualbox

```
mkdir /var/www/.config/
chown vbox:vbox /var/www/.config/
```

## Setup some aliases for root
```
cat >>~/.bash_aliases<<END
alias deploy='/var/www/railsapps/i-tee/utils/deploy.sh'
alias restart='touch /var/www/railsapps/i-tee/tmp/restart.txt'
END

```

## Create directory for temp files

	mkdir /var/www/railsapps/i-tee/tmp
	chown www-data:www-data /var/www/railsapps/i-tee/tmp/

## Performance tuning

1. mount /var/labs with noatime,nodiratime options

Sample line for /etc/fstab:
    
    /dev/YOURDISK    /var/labs       ext4    defaults,noauto,noatime,nodiratime      0       0


2. set  vm.dirty_background_ratio=1, vm.dirty_ratio=60 in /etc/sysctl.d/local.conf


## Test your installation
Test your installation using web browser

https://YOUR-FQDN:4433 << change phpvitualbox default admin password!!!

https://YOUR-FQDN

## TODO and configuration hints

```
  # hostname for rdp sessions
  config.rdp_host = 'elab.itcollege.ee'
  # port prefix for rdp sessions
  config.rdp_port_prefix = '10'
```

Integration with btrfs deduplication tool: https://github.com/g2p/bedup

http://www.vionblog.com/virtualbox-4-3-autostart-debian-wheezy/


https://gist.github.com/mikedevita/7461832


### Integrating with Active Directory or SAMBA4

1. Create service account to SAMBA4|AD


2. Change config/initializers/devise.rb file to accept ldap bind with administrator user (or service account for i-tee)

```
#config.ldap_use_admin_to_bind = false <-- Change this to true in case you don't use anonymous bind
config.ldap_use_admin_to_bind = true

```

3.  change config/ldap.yml

```
authorizations: &AUTHORIZATIONS
  
#  group_base: cn=Groups,dc=itcollege,dc=ee as a sample

  group_base: cn=Groups,dc=YOURDC,dc=YOUR

  require_attribute:
    objectClass: inetOrgPerson
    authorizationRole: postsAdmin


production:
  host: YOUR_DOMAIN_CONTOLLER
  port: 636
  attribute: sAMAccountName 
  base: dc=YOURDC,dc=YOUR
  admin_user: rfsrv@rangeforce.com
  admin_password: YOUR_SERVICE_ACCOUNT_PASSWORD
  ssl: true
  # <<: *AUTHORIZATIONS
```

In casse you do not have a Active Directory or LDAP server you can user token-based authentication instead.

To create the first admin user use the rails console:

```
	User.create!(username: "admin", email: "admin email", name: "admin name", role: 2, token_expires: 3.years.from_now, password: "someStrongPassword")
	u = User.first
	u.authentication_token = "somekey"
	u.save
```

and to log in use https://www.yourhost.com?auth_token=somekey


##For developers

For documentation:

	wget http://github.github.com/github-flavored-markdown/shared/css/documentation.css
	gem install gimli

	gimli -f ./README.md -s documentation.css

#Guest setup
-Virtualbox additions


# Some common errors

Error in creating database using rake
```
	rake aborted!
	Psych::SyntaxError: (<unknown>): found character that cannot start any token while scanning for the next token at line 2 column 1
	/usr/lib/ruby/1.9.1/psych.rb:203:in `parse'
	/usr/lib/ruby/1.9.1/psych.rb:203:in `parse_stream'
	/usr/lib/ruby/1.9.1/psych.rb:151:in `parse'
```
This indicates that you have tab in yaml file. Replace tabs with spaces.

# Authors
Tiia Tänav

Margus Ernits

Carolyn Fischer (retired)

Aivar Guitar (retired)

Madis Toom (retired)

