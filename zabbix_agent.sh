#!/bin/bash
#
# Use this script to create the Zabbix agent config and install the repo specific agent package
#
# Miniumum requirements
# LogFile=$zabbixDir\zabbix_agentd.log
# Server=127.0.0.1
# ServerActive=127.0.0.1
# Hostname=blahblahblah
#
# TODO check if the binaries have changed before downloading, maybe s3 hash?
# TODO run this at boot somehow



now=$(date +%Y%m%d%H%M)
name=$(cat /proc/sys/kernel/hostname | tr '[:upper:]' '[:lower:]')
conf="/etc/zabbix/zabbix_agentd.conf"
log="/var/log/zabbix/zabbix_agentd.log"

# Introspection
if [[ ! -z $(lsb_release -a 2>/dev/null) ]]; then
        export LSB=1
        export OS_TYPE=$(lsb_release -i | cut -d":" -f2- | sed -e 's/^[[:space:]]*//')
        export OS_VER=$(lsb_release -sr | cut -d'.' -f1)
        export OS_CODENAME=$(lsb_release -c | cut -d":" -f2- | sed -e 's/^[[:space:]]*//')
        export OS_DIST=$(grep -h "CODENAME=" /etc/*-release | sed 's/\(.*CODENAME\=\|\""\"\)//' | sed 's/\"//g' | uniq -f1)
        export MT_TYPE=$(/usr/sbin/dmidecode -t system | grep 'Product Name\:' | sed 's/Product Name\://' | tr -s " ")
else
    OS_ID=$(grep -h -e "^ID=" /etc/*-release | sed 's/\(ID\=\)//' | sed 's/\"//g')
    OS_TYPE=$(grep -h "PRETTY_NAME" /etc/*-release | sed 's/\(PRETTY_NAME\=\|\""\"\)//' | sed 's/\"//g' | tr -d '[:space:]' )
    OS_VER=$(grep -h "VERSION_ID=" /etc/*-release | cut -d'"' -f2 )
    OS_DIST=$(grep -h "CODENAME=" /etc/*-release | sed 's/\(.*CODENAME\=\|\""\"\)//' | sed 's/\"//g' | uniq -f1)
    MT_TYPE=$(/usr/sbin/dmidecode -t system | grep 'Product Name\:' | sed 's/Product Name\://' | tr -s " ")
    CENTOS_OLD=$(grep -h "CentOS" /etc/centos-release)
    RHEL_OLD=$(grep -h "Red Hat" /etc/*-release)
fi

# Is the system an AWS EC2 instance?
# Courtesy of https://serverfault.com/questions/462903/how-to-know-if-a-machine-is-an-ec2-instance
# This first, simple check will work for many older instance types.
if [ -f /sys/hypervisor/uuid ]; then
  # File should be readable by non-root users.
  if [ `head -c 3 /sys/hypervisor/uuid` == "ec2" ]; then
    export ec2=1
  else
    export ec2=0
  fi

# This check will work on newer m5/c5 instances, but only if you have root!
elif [ -r /sys/devices/virtual/dmi/id/product_uuid ]; then
  # If the file exists AND is readable by us, we can rely on it.
  if [ `head -c 3 /sys/devices/virtual/dmi/id/product_uuid` == "EC2" ]; then
    export ec2=1
  else
    export ec2=0
  fi

else
  # Fallback check of http://169.254.169.254/. If we wanted to be REALLY
  # authoritative, we could follow Amazon's suggestions for cryptographically
  # verifying their signature, see here:
  #    https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
  # but this is almost certainly overkill for this purpose (and the above
  # checks of "EC2" prefixes have a higher false positive potential, anyway).
  if $(curl -s -m 1 http://169.254.169.254/latest/dynamic/instance-identity/document | grep -q availabilityZone) ; then
    export ec2=1
  else
    export ec2=0
  fi
fi

# Get the VM/Physical metadata
case $MT_TYPE in
    *VM[wW]are*|*"HVM domU"*|*Nova*|*Virtual*|*EC2*|*"Standard PC (i440FX + PIIX, 1996)"*) mt="VM" ;;
    *Dell*|*HP*|*IBM*|*SuperMicro*|*Cisco*) mt="Physical" ;;
    *) mt="PlatformUnknown"
esac
metadata+=($mt)


# Install the agent
case $OS_TYPE in
    *EnterpriseEnterpriseServer*)
        echo "OracleLinux!"
        case $OS_VER in
            [5-8])
            if [[ ! $(rpm -qa | grep zabbix-agent) == *zabbix-agent-4.0.17-1.el* ]]; then
                old=$(rpm -qa | grep zabbix-agent)
                rpm -e $old
                wget -O "zabbix-agent-4.0.17-1.el${OS_VER}.x86_64.rpm" "http://repo.zabbix.com/zabbix/4.0/rhel/${OS_VER}/x86_64/zabbix-agent-4.0.17-1.el${OS_VER}.x86_64.rpm"
                rpm -i zabbix-agent-4.0.17-1.el${OS_VER}.x86_64.rpm
                fi
            if [[ -f $conf ]]; then
            mv $conf $conf$now
            fi
            ;;
            *)
            echo "OracleLinux version not detected!"
            ;;
        esac
        ;;
    *RedHat*|*CentOS*)
        echo "RHEL!"
        case $OS_VER in
            [5-8])
            if [[  $(rpm -qa | grep zabbix-agent) != "zabbix-agent-4.0.17-1.el${OS_VER}.x86_64" ]]; then
                #old=$(rpm -qa | grep zabbix-agent)
                #rpm -e $old
                wget -O "zabbix-agent-4.0.17-1.el${OS_VER}.x86_64.rpm" "http://repo.zabbix.com/zabbix/4.0/rhel/${OS_VER}/x86_64/zabbix-agent-4.0.17-1.el${OS_VER}.x86_64.rpm"
                rpm -i zabbix-agent-4.0.17-1.el${OS_VER}.x86_64.rpm
                fi
            if [[ -f $conf ]]; then
            mv $conf $conf$now
            fi
            ;;
            *)
            echo "RHEL version not detected!"
            ;;
        esac
        ;;
    *Amazon*)
        echo "AmazonLinux!"
        case $OS_VER in
            [1-2])
            # AmzonLinux 1 = RHEL6
            # AmzonLinux 2 = RHEL7
            if [[ ! $(rpm -qa | grep zabbix-agent) == *zabbix-agent-4.0.17-1.el* ]]; then
                old=$(rpm -qa | grep zabbix-agent)
                rpm -e $old
                case $OS_VER in
                1)
                    wget -O "zabbix-agent-4.0.17-1.el6.x86_64.rpm" "http://repo.zabbix.com/zabbix/4.0/rhel/6/x86_64/zabbix-agent-4.0.17-1.el6.x86_64.rpm"
                    rpm -i zabbix-agent-4.0.17-1.el6.x86_64.rpm
                    ;;
                2)
                    wget -O "zabbix-agent-4.0.17-1.el7.x86_64.rpm" "http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-agent-4.0.17-1.el7.x86_64.rpm"
                    rpm -i zabbix-agent-4.0.17-1.el7.x86_64.rpm
                    ;;
                esac
            fi
            if [[ -f $conf ]]; then
            mv $conf $conf$now
            fi
            ;;
        *)
        echo "AmazonLinux version not detected!"
        ;;
    esac
    ;;
    *CentOS*)
        case $OS_VER in
            [6-9])
            if [[ -z $(yum list installed | grep zabbix-agent) ]]; then
                rpm -Uvh "http://repo.zabbix.com/zabbix/4.0/rhel/${OS_VER}/x86_64/zabbix-release-4.0-17.el${OS_VER}.noarch.rpm"
                yum -y install zabbix-agent
                fi
            if [[ -f $conf ]]; then
                mv $conf $conf$now
            fi
            ;;
            *)
            echo "Not CentOS maybe?"
            ;;
        esac
        ;;
    *Debian*)
        # Don't use my budget OS_VER var!
        echo "Debian!"
        if [[ ! $(sudo apt list --installed 2>/dev/null | grep zabbix-agent | grep "4.0.17-1" ) == *installed* ]] ; then
            wget -O "zabbix-release_4.0-2+${OS_DIST}_all.deb" "http://repo.zabbix.com/zabbix/4.0/debian/pool/main/z/zabbix-release/zabbix-release_4.0-2+${OS_DIST}_all.deb"
            dpkg -i zabbix-release_4.0-2+${OS_DIST}_all.deb
            apt -y install zabbix-agent
        fi
        if [[ -f $conf ]]; then
        mv $conf $conf$now
        fi
        ;;
    *Ubuntu*)
        # Don't use my budget OS_VER var!
        echo "Ubuntu!"
        if [[ ! $(sudo apt list --installed 2>/dev/null | grep zabbix-agent | grep "4.0.17-1" ) == *installed* ]] ; then
            wget -O "zabbix-release_4.0-2+${OS_DIST}_all.deb" "http://repo.zabbix.com/zabbix/4.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.0-2+${OS_DIST}_all.deb"
            dpkg -i zabbix-release_4.0-2+${OS_DIST}_all.deb
            apt -y install zabbix-agent
        fi
        if [[ -f $conf ]]; then
        mv $conf $conf$now
        fi
        ;;
        *)
        echo "no match!"
esac
