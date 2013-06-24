#!/bin/bash
# 
# This script can be quick thin-provisioning on KVM/Libvirt.
# It requires nbd, qemu-nbd, and kpartx.
# I checked this on Fedora17
# 

export LANG=C

while getopts o:s:n:h:i:k: OPT
do
  case $OPT in
    "o" ) FLG_O="TRUE" ; ORGVM="$OPTARG" ;;
    "s" ) FLG_S="TRUE" ; SOURCEIMAGE="$OPTARG" ;;
    "n" ) FLG_N="TRUE" ; NEWVM="$OPTARG" ;;
    "h" ) FLG_H="TRUE" ; VMHOSTNAME="$OPTARG" ;;
    "i" ) FLG_I="TRUE" ; IPADDRESS="$OPTARG" ;;
    "k" ) FLG_K="TRUE" ; PUBKEY="$OPTARG" ;;
      * ) echo "Usage: $CMDNAME [-o ORIGINAL-VM] [-s SOURCE-IMAGE] [-n NEW-VM-NAME] [-h NEW-HOSTNAME] [-i NEW-IP] [-k PUB-KEY]" 1>&2
          exit 1 ;;
  esac
done

VIRT_IMG_DIR=/var/lib/libvirt/images
WORKDIR=/tmp/virt-clone-thin-`uuidgen`

echo ---------------------
echo "Original VM  :" ${ORGVM:?" -o is not set"}
echo "Source Image :" ${SOURCEIMAGE:?" -s is not set"}
echo "New VM name  :" ${NEWVM:?" -n is not set"}
echo "New host name:" ${VMHOSTNAME:?" -h is not set"}
echo "New host ip  :" ${IPADDRESS:?" -i is not set"}
echo "Public key   :" ${PUBKEY:?" -i is not set"}
echo ---------------------

mkdir -p ${WORKDIR}/mnt


lsmod |grep nbd
RETVAL=$?
if [ $RETVAL != 0 ]; then
   modprobe nbd
   RETVAL=$?
   if [ $RETVAL != 0 ]; then
      echo "this script need NBD."
      exit 1
   fi
fi

if [ ! -f ${PUBKEY} ]; then
   echo "${PUBKEY} dose not exist."
   exit 1
fi

virt-clone -o ${ORGVM} -n ${NEWVM} -f ${VIRT_IMG_DIR}/${NEWVM}.qcow2 --print-xml > ${WORKDIR}/temp.xml

if [ -f ${VIRT_IMG_DIR}/${NEWVM}.qcow2 ]; then
   echo "${VIRT_IMG_DIR}/${NEWVM}.qcow2 is already exist"
   exit 1
fi

qemu-img create -b ${SOURCEIMAGE} -f qcow2 ${VIRT_IMG_DIR}/${NEWVM}.qcow2
qemu-nbd -c /dev/nbd0 ${VIRT_IMG_DIR}/${NEWVM}.qcow2
kpartx -av /dev/nbd0
mount -t ext4 /dev/mapper/nbd0p2 ${WORKDIR}/mnt

cd ${WORKDIR}/mnt/etc/sysconfig
cat << EOF > network
NETWORKING=yes
HOSTNAME=${VMHOSTNAME}
GATEWAY=192.168.128.1
EOF

cd ${WORKDIR}/mnt/etc/sysconfig/network-scripts
cat << EOF > ifcfg-eth0
DEVICE=eth0
BOOTPROTO=static
IPADDR=${IPADDRESS}
NETMASK=255.255.255.0
ONBOOT=yes
NM_CONTROLLED=no
EOF

if [ ! -d ${WORKDIR}/mnt/root/.ssh ]; then
   mkdir -p ${WORKDIR}/mnt/root/.ssh
   chmod 700 ${WORKDIR}/mnt/root/.ssh
fi

cd ${WORKDIR}/mnt/root/.ssh

if [ -f authorized_keys ]; then
   cat ${PUBKEY} >> authorized_keys
else
   cat ${PUBKEY} >> authorized_keys
   chmod 600 authorized_keys
fi

echo --- network ------------------
cat ${WORKDIR}/mnt/etc/sysconfig/network
echo --- ifcfg-eth0 ---------------
cat ${WORKDIR}/mnt/etc/sysconfig/network-scripts/ifcfg-eth0
echo --- authorized_keys ----------
cat ${WORKDIR}/mnt/root/.ssh/authorized_keys
echo ------------------------------

cd /tmp

umount ${WORKDIR}/mnt
kpartx -dv /dev/nbd0
qemu-nbd -d /dev/nbd0

virsh define ${WORKDIR}/temp.xml
virsh pool-refresh default
virsh list --all
virsh vol-list default

rm -Rf ${WORKDIR}

