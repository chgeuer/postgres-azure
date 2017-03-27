#!/bin/bash

#
# ./ebs_raid0.sh <mount_point> 
#

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters: ./ebs_raid0.sh <mount_point>"
    exit
fi

mount_point=$1

drive_names=$(lsblk | grep ^sd | grep -w -v -e sda -e sdb | awk '{print $1;}')
count=0
drives=""
for i in $drive_names; do
	drives="$drives /dev/$i"
	count=$((count+1))
done

mkdir -p "${mount_point}"

root_drive=$(df -h | grep /dev/sda)

if [[ "$root_drive" == "" ]]; then
    echo "Detected 'xvd' drive naming scheme \(root: $root_drive\)"
    DRIVE_SCHEME='xvd'
else
    echo "Detected 'sd' drive naming scheme \(root: $root_drive\)"
    DRIVE_SCHEME='sd'
fi

partprobe
mdadm --verbose --create /dev/md1 --level=0 --name=raid -c256  --raid-devices=$count "$drives"
md=$(grep sdc /proc/mdstat | cut -d':' -f1)

echo "dev.raid.speed_limit_min = 1000000" >> /etc/sysctl.conf
echo "dev.raid.speed_limit_max = 2000000" >> /etc/sysctl.conf

echo DEVICE "$drives" | tee /etc/mdadm.conf
mdadm --detail --scan | tee -a /etc/mdadm.conf


mkfs.xfs -f -d su=256k,sw=4 -l version=2,su=256k -i size=1024 "/dev/$md"
mount -t xfs -o rw,uqnoenforce,gqnoenforce,noatime,nodiratime,logbufs=8,logbsize=256k,largeio,inode64,swalloc,allocsize=131072k,nobarrier "/dev/${md}" "${mount_point}"


for i in $drive_names; do
	echo 8192 > "/sys/block/$i/queue/nr_requests"
	echo noop > "/sys/block/$i/queue/scheduler"
done

for i in $md
do
	echo noop > "/sys/block/$i/queue/scheduler"
	echo 256 > "/sys/block/$i/queue/read_ahead_kb"
	echo 0 > "/sys/block/$i/queue/rotational"
done

echo 30 > /proc/sys/vm/vfs_cache_pressure
echo never > /sycs/kernel/mm/transparent_hugepage/enabled 
echo 20 > /proc/sys/vm/dirty_ratio
echo 10 > /proc/sys/vm/dirty_background_ratio

# Remove xvdb/sdb from fstab
chmod 777 /etc/fstab
sed -i "/${DRIVE_SCHEME}b/d" /etc/fstab

# Make raid appear on reboot
echo "/dev/$md $mount_point xfs noatime 0 0" | tee -a /etc/fstab
