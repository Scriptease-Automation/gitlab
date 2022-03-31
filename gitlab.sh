#!/bin/bash
# Owner ISTC Foundation
# Created By Vardges Hovhannisyan
# Installing Gitlab
#/////////////////////////////////////////////////////////
# Collecting all neccessary data and configruing variables
#/////////////////////////////////////////////////////////
#########################################################################################################
#Standalone Variables
#########################################################################################################
letsfolder=/etc/letsencrypt/live/
gitlabssl=/etc/gitlab/ssl/
gitlabconf=/etc/gitlab/gitlab.rb
#########################################################################################################
#Input Variables
#########################################################################################################
while getopts d:r:n: name
do
    case "${name}" in
        d) domain=${OPTARG};;
        r) registry=${OPTARG};;
        n) regdomain=${OPTARG};;
        *) echo "Invalid option: -$name" ;;
    esac
done
echo "Domain: $domain";
echo "Registry: $registry";
echo "Registry Domain: $regdomain"

certfile=$letsfolder$regdomain/fullchain.pem
keyfile=$letsfolder$regdomain/privkey.pem

regstandurl="# registry_external_url 'https://registry.example.com'"
regcoreurl="registry_external_url 'https://$regdomain'"


#########################################################################################################
#Setting Hostname
#########################################################################################################
NEW_HOSTNAME=$domain
echo $NEW_HOSTNAME > /proc/sys/kernel/hostname
sed -i 's/127.0.1.1.*/127.0.1.1\t'"$NEW_HOSTNAME"'/g' /etc/hosts
echo $NEW_HOSTNAME > /etc/hostname
service hostname start
su $SUDO_USER -c "xauth add $(xauth list | sed 's/^.*\//'"$NEW_HOSTNAME"'\//g' | awk 'NR==1 {sub($1,"\"&\""); print}')"

#########################################################################################################
#Checking OS
#########################################################################################################

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=`lowercase \`uname\``
KERNEL=`uname -r`
MACH=`uname -m`

if [ "{$OS}" == "windowsnt" ]; then
    OS=windows
elif [ "{$OS}" == "darwin" ]; then
    OS=mac
else
    OS=`uname`
    if [ "${OS}" = "SunOS" ] ; then
        OS=Solaris
        ARCH=`uname -p`
        OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
    elif [ "${OS}" = "AIX" ] ; then
        OSSTR="${OS} `oslevel` (`oslevel -r`)"
    elif [ "${OS}" = "Linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            DistroBasedOn='RedHat'
            DIST=`cat /etc/redhat-release |sed s/\ release.*//`
            PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/SuSE-release ] ; then
            DistroBasedOn='SuSe'
            PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
            REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
        elif [ -f /etc/mandrake-release ] ; then
            DistroBasedOn='Mandrake'
            PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/debian_version ] ; then
            DistroBasedOn='Debian'
            DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
            PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
            REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
        fi
        if [ -f /etc/UnitedLinux-release ] ; then
            DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
        fi
        OS=`lowercase $OS`
        DistroBasedOn=`lowercase $DistroBasedOn`
        readonly OS
        readonly DIST
        readonly DistroBasedOn
        readonly PSUEDONAME
        readonly REV
        readonly KERNEL
        readonly MACH
    fi

fi
echo $OS
echo $KERNEL
echo $MACH
echo $DIST

if [[ ${DIST} = "Ubuntu"* ]]; 
    then
        sudo apt-get update
        sudo apt-get install -y curl openssh-server ca-certificates tzdata perl
        sudo apt-get install -y postfix
        curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
        sudo EXTERNAL_URL="https://$domain" apt-get install gitlab-ee
        echo "Username for ROOT Profle:  root"
        echo "Random Password for 24 hours: $randpass"

elif [[ ${DIST} = "Debian"* ]]; 
    then
        sudo apt-get update
        sudo apt-get install -y curl openssh-server ca-certificates perl
        sudo apt-get install -y postfix
        curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
        sudo EXTERNAL_URL="https://$domain" apt-get install gitlab-ee
        echo "Username for ROOT Profle:  root"
        echo "Random Password for 24 hours: $randpass"

elif [[ ${DIST} = "Cent"* || ${DIST} = "Red"* ]]; 
    then
        sudo dnf install -y curl policycoreutils openssh-server perl
        # Enable OpenSSH server daemon if not enabled: sudo systemctl status sshd
        sudo systemctl enable sshd
        sudo systemctl start sshd

        #Check if opening the firewall is needed with: sudo systemctl status firewalld
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo systemctl reload firewalld

        #Installing Postfix to send notification emails
        sudo dnf install postfix
        sudo systemctl enable postfix
        sudo systemctl start postfix

        #Adding the GitLab package repository.
        curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
        sudo EXTERNAL_URL="https://$domain" dnf install -y gitlab-ee
        echo "Username for ROOT Profle:  root"
        echo "Random Password for 24 hours: $randpass"

elif [[ ${DIST} = "openSUSE"* ]]; 
    then
        sudo zypper install curl openssh perl
        # Enable OpenSSH server daemon if not enabled: sudo systemctl status sshd
        sudo systemctl enable sshd
        sudo systemctl start sshd

        # Check if opening the firewall is needed with: sudo systemctl status firewalld
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo systemctl reload firewalld

        #Installing Postfix to send notification emails
        sudo zypper install postfix
        sudo systemctl enable postfix
        sudo systemctl start postfix

        #Adding the GitLab package repository.
        curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
        sudo EXTERNAL_URL="https://$domain" zypper install gitlab-ee
        randpass=$(cat ~/.tmp.pass)
        echo "Username for ROOT Profle:  root"
        echo "Random Password for 24 hours: "
        sudo cat /etc/gitlab/initial_root_password | grep Password: 

else
    echo "
        Sorry, this operating system is not supported, 
        Please see the supported OS list in the web page below.
        https://about.gitlab.com/install/
        "
fi
if [[ ${registry} = "enabled" ]]; 
    then
        echo "Stopping GitLab to configure registry"
        sudo gitlab-ctl stop
        if [[ ${DIST} = "Ubuntu"* ]]; then
            #Installing Certbot 
            sudo snap install core
            sudo snap install --classic certbot
            sudo ln -s /snap/bin/certbot /usr/bin/certbot
  
        elif [[ ${DIST} = "CentOS"* ]]; then
            # CentOS
            #Installing Snapd
            sudo yum install epel-release
            sudo yum install snapd
            sudo systemctl enable --now snapd.socket
            sudo ln -s /var/lib/snapd/snap /snap

            #Installing Certbot
            sudo snap install core
            sudo snap install --classic certbot
            sudo ln -s /snap/bin/certbot /usr/bin/certbot
            
        elif [[ ${DIST} = "Red"* ]]; then
            # Red Hat
            #Installing Snapd
            sudo yum install epel-release
            sudo yum install snapd
            sudo systemctl enable --now snapd.socket
            sudo ln -s /var/lib/snapd/snap /snap

            #Installing Certbot
            sudo snap install core
            sudo snap install --classic certbot
            sudo ln -s /snap/bin/certbot /usr/bin/certbot
            
        elif [[ ${DIST} = "openSUSE"* ]]; then
            # openSUSE
            #Installing Snapd
            sudo zypper addrepo --refresh https://download.opensuse.org/repositories/system:/snappy/openSUSE_Leap_15.2 snappy
            sudo zypper --gpg-auto-import-keys refresh
            sudo zypper dup --from snappy
            sudo zypper install snapd
            source /etc/profile
            sudo systemctl enable --now snapd
            sudo systemctl enable --now snapd.apparmor

            #Install Certbot
            sudo snap install core
            sudo snap install --classic certbot
            sudo ln -s /snap/bin/certbot /usr/bin/certbot
            
        
        elif [[ ${DIST} = "Debian"* ]]; then
            # debian
            #Installing Certbot 
            sudo snap install core
            sudo snap install --classic certbot
            sudo ln -s /snap/bin/certbot /usr/bin/certbot

        fi
        sudo certbot certonly --agree-tos --standalone --preferred-challenges  http -d $regdomain --register-unsafely-without-email

        if test -f "$certfile";
            then
                cp $certfile $gitlabssl$regdomain.crt
                cp $keyfile $gitlabssl$regdomain.key
                chmod 600 $gitlabssl$regdomain.*
                echo "$regcoreurl" >> $gitlabconf
                sudo gitlab-ctl reconfigure
                sudo gitlab-ctl start

        elif [[ ${registry} = "none" ]];
            then
                echo "Setting up Gitlab without container registry"
        else
                echo "Unknown Option: $registry" 
    echo "Username for ROOT Profle:  root"
    echo "Random Password for 24 hours:"
    sudo cat /etc/gitlab/initial_root_password | grep Password:
fi
fi
