#!/bin/bash

ip=$(ip route |grep ^default | grep -Eo "dev.*" | awk '{print $2}' | xargs -I {} ip addr show "{}" | grep -Eo "inet .*/" |awk '{print $2}' | tr -d /)

mount |grep nfs
if [ "x$ip" == "x" ]; then
  echo "No network, doing nothing"
  exit
fi

while read mount; do
  mountpoint=$(echo "$mount" | awk '{print $3}'); 
  mountserver=$(echo "$mount" | awk '{print $1}');
  mountoptions=$(echo "$mount" | awk '{print $6}' | tr -d "\(\)");
  clientaddr=$(echo "$mountoptions" | grep -Eo "clientaddr=[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" |grep -Eo "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}")
  mountoptions_new=$(echo "$mountoptions" | sed "s/clientaddr=.*,/clientaddr=$ip,/g");
  echo "$mountoptions_new"
  
  #somehow, mount clientaddr doesn't change so we ignore this
  #if [ "$clientaddr" = "$ip" ]; then
    #echo "$mountserver didn't switch ips ($ip, $clientaddr)"
    #continue;
  #fi

  echo "Remounting $mountserver"
  umount -f "$mountpoint" -t nfs
  mount -v "$mountserver" "$mountpoint" -o "$mountoptions_new"
  
  ls "$mountpoint" > /dev/null
done < <(mount | grep -E " type nfs4? ")
