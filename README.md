Setting up PostgreSQL
=====================


# Login to Azure

- Download publish settings at https://manage.windowsazure.com/publishsettings/index?client=xplat 

```
npm install azure-cli
azure account import "Windows Azure MSDN - Visual Studio Ultimate-11-4-2014-credentials.publishsettings"
azure account set "internal"
azure account list
```


# Get the image

Debian Wheezy Image from https://vmdepot.msopentech.com/Vhd/Show?vhdId=65&version=400


```
azure vm list --json
azure vm create DNS_PREFIX --community vmdepot-65-6-32 --virtual-network-name   -l "West Europe" USER_NAME [PASSWORD] [--ssh] [other_options]

```

# PostgreSQL

## Update local system

```
aptitude update
```

## Register postgreSQL 

As documented under https://wiki.postgresql.org/wiki/Apt

```
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

sudo apt-get install wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install postgresql-9.3 pgadmin3
```






