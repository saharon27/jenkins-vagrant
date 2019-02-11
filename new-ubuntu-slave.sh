#!/bin/bash

randomNum=$( shuf -i 0-65000 -n 1 )
vmName="ubuntu_${randomNum}_slave"
echo ${vmName}


# Find config lines of ubuntu slave vm in vagrantfile and duplicate it.
# After duplicating edit the lines to config a new vm.
awk '/config.vm.define :ubuntu_slave/,/end/{
   H = H RS $0
   if ( $0 ~ /end/ ) {
      g = H
      sub("ubuntu_slave","'${vmName}'",g)
      $0 = g H
   } else { next }
}1'   Vagrantfile > temp.txt && mv temp.txt Vagrantfile

vagrant up ${vmName} 

# # add the ubuntu slave node.
# # see http://javadoc.jenkins-ci.org/jenkins/model/Jenkins.html
# # see http://javadoc.jenkins-ci.org/jenkins/model/Nodes.html
# # see http://javadoc.jenkins-ci.org/hudson/slaves/DumbSlave.html
# # see http://javadoc.jenkins-ci.org/hudson/model/Computer.html

# jgroovy = <<'EOF'
# import jenkins.model.Jenkins
# import hudson.slaves.DumbSlave
# import hudson.slaves.CommandLauncher

# node = new DumbSlave(
#     "ubuntu",
#     "/var/jenkins",
#     new CommandLauncher("ssh ubuntu.jenkins.example.com /var/jenkins/bin/jenkins-slave"))
# node.numExecutors = 3
# node.labelString = "ubuntu 18.04 linux amd64"
# Jenkins.instance.nodesObject.addNode(node)
# Jenkins.instance.nodesObject.save()
# EOF