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


Create an A5 instance
```

# PostgreSQL

## Update local system

```
aptitude update
```

## Install PostgreSQL 

Install PostgreSQL, as documented under https://wiki.postgresql.org/wiki/Apt 

```
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

aptitude install wget ca-certificates

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

aptitude update && aptitude upgrade

aptitude install postgresql-9.3
```

## Edit postgresql.conf

Uncomment listen_addresses

```
listen_addresses = '*'
```

Switch off SSL

```
ssl = false
```

