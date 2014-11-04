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

## Edit /etc/postgresql/9.3/main/postgresql.conf

Uncomment listen_addresses (Database only reachable through jump host)

```
listen_addresses = '*'
```

Switch off SSL

```
ssl = false
```

Rule of thumb for shared buffers: 25% of RAM should be shared buffers, on an A5 

```
shared_buffers = 4GB
work_mem = 256MB
maintenance_work_mem = 512MB
```

The write-ahead-log needs to be merged at regular checkpoints into the tables:

```
checkpoint_segments = 64                # was 3 previously in logfile segments, min 1, 16MB each
checkpoint_timeout = 1min               # range 30s-1h
checkpoint_completion_target = 0.8      # checkpoint target duration, 0.0 - 1.0
```

Put replication configuration into dedicated file

```
include_if_exists = 'replication.conf'
```

# Mount data disks

- One data disk for pg_xlog
- Multiple data disks in a [RAID](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-configure-raid/)  

- Use 'cfdisk' on /dev/sdc and create an 'FD' (RAID autodetect) disk





# Questions:

For the block device driver for Azure Linux IaaS, what's supported or optimal? open_datasync, fdatasync (default on Linux), fsync, fsync_writethrough, open_sync. This is relevant to configure wal_sync_method

