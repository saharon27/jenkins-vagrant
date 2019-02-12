# This script will create a new Jenkins env. based on the vagrant file
# Basic setup includes: 1 vm as Jenkins Master and 1 vm as Ubuntu 18.04 slave.
# There are preperations for Windows slave --> If you wish to deploy it just run the command 'vagrant up windows'

vagrant up jenkins
if [ $? -ne 0 ] ; then
    echo "Something went wrong. Please check log above !!!!"
else echo 'Jenkins Master is Up !'
fi

vagrant up ubuntu_slave
if [ $? -ne 0 ] ; then
    echo "Something went wrong. Please check log above !!!!"
else echo 'ubuntu_slave is Up !'
fi



