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

- Debian Wheezy Image from https://vmdepot.msopentech.com/Vhd/Show?vhdId=65&version=400
- http://blogs.msdn.com/b/silverlining/archive/2012/10/25/exporting-and-importing-vm-settings-with-the-azure-command-line-tools.aspx


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

aptitude install mdadm
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

# Attach, mount and stripe data disks

- Multiple data disks in a [RAID](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-configure-
raid/)  in order to achieve higher I/O, given current limitation of 500 IOPS per data disk. 
- One data disk for pg_xlog

```
azure vm disk attach-new postgresvm1 1023 http://postgresdisks.blob.core.windows.com/vhds/postgresvm1-datastripe-1.vhd
azure vm disk attach-new postgresvm1 1023 http://postgresdisks.blob.core.windows.com/vhds/postgresvm1-datastripe-2.vhd
azure vm disk attach-new postgresvm1 1023 http://postgresdisks.blob.core.windows.com/vhds/postgresvm1-xlog.vhd
```

- Use 'cfdisk' on /dev/sdc and create a primary partition of tyoe 'FD' (RAID autodetect) for RAID for pg_data
- Use 'cfdisk' on /dev/sdd and create a primary partition of tyoe 'FD' (RAID autodetect) for RAID for pg_data
- Use 'cfdisk' on /dev/sde and create a primary partition of tyoe '8E' (LVM) for pg_xlog

```
aptitude install mdadm

mdadm --create /dev/md0 --level 0 --raid-devices 2 /dev/sdc1 /dev/sdd1

aptitude install lvm2

# create physical volume
pvcreate /dev/md0

# create volume group
vgcreate data /dev/md0

# create logical volume 
lvcreate -n pgdata -l100%FREE data

# show volume group information
vgdisplay

# Now 
ls -als /dev/data/pgdata

aptitude install xfsprogs

# mkfs -t xfs /dev/data/pgdata
mkfs.xfs /dev/data/pgdata
```

## Setup automount

```
$ tail /etc/fstab

/dev/mapper/data-pgdata /space/pgdata xfs defaults 0 0
/dev/mapper/xlog-pgxlog /space/pgxlog xfs defaults 0 0
```

## Move database files into striped volume 

```
mv /var/lib/postgresql/9.3 /space/pgdata/
ln -s /space/pgdata/9.3 /var/lib/postgresql/9.3
```


# Questions:

- For the block device driver for Azure Linux IaaS, what's supported or optimal? open_datasync, fdatasync (default on Linux), fsync, fsync_writethrough, open_sync. This is relevant to configure wal_sync_method
- It seems that the guest OS does not see a detached data disk. An attached disk shows up in dmesg, while a detach process doesn't show up. When trying to open a formerly attached device (with cfdisk), the 

# Unix vodoo :-)

## See what's happening 

```
watch dmesg  \| tail -5
```

