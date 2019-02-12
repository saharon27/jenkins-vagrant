#!/bin/bash
set -eux

randomNum=$( shuf -i 0-65000 -n 1 )
machineName="ubuntu-${randomNum}-slave"
vmName="ubuntu_${randomNum}_slave"
ipVarName="config_${vmName}_ip"
fullfqdn="config_${vmName}_fqdn"
newIpAddrs=10.10.10.$( shuf -i 103-190 -n 1 )
jenkinsfqdn='jenkins.example.com'
echo ${machineName}


# Find config lines of ubuntu slave vm in vagrantfile and duplicate it.
# After duplicating edit the lines to config a new vm.
awk '/config.vm.define :ubuntu_slave/,/end/{
   H = H RS $0
   if ( $0 ~ /end/ ) {
      g = H
      sub("ubuntu_slave","'${vmName}'",g)
      sub("config_ubuntu_fqdn","'${fullfqdn}'",g)
      sub("config_ubuntu_ip","'${ipVarName}'",g)
      $0 = g H
   } else { next }
}1'   Vagrantfile > temp.txt && mv temp.txt Vagrantfile

# Adding new ip address to Vagrantfile
awk '/# Slaves params/{
   print $0 RS "'${fullfqdn}'  = \"'${machineName}'.#{config_jenkins_fqdn}\"" RS "'${ipVarName}'    = '"'"${newIpAddrs}"'"'" 
   ;next}1' Vagrantfile > temp.txt && mv temp.txt Vagrantfile

# create the vm using vagrant
vagrant up ${vmName}

# creating new slave in jenkins
#vagrant ssh -c "${JCLI} -auth vagrant:vagrant get-node ubuntu-slave | ${JCLI} -auth vagrant:vagrant create-node ${machineName}" jenkins
JCLI="java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080"

vagrant ssh -c 'cat <<EOF | java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 -auth vagrant:vagrant create-node '$machineName'
<slave>
  <name>'$machineName'</name>
  <description></description>
  <remoteFS>/var/jenkins</remoteFS>
  <numExecutors>3</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.slaves.CommandLauncher" plugin="command-launcher@1.3">
    <agentCommand>ssh '$machineName'.jenkins.example.com /var/jenkins/bin/jenkins-slave</agentCommand>
  </launcher>
  <label>ubuntu 18.04 linux amd64</label>
  <nodeProperties/>
</slave>
EOF' jenkins

# adding new slave to hosts on jenkins master vm
vagrant ssh -c "echo '${newIpAddrs} ${machineName}.${jenkinsfqdn}' | sudo tee -a /etc/hosts" jenkins
