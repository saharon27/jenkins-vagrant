#!/bin/bash
set -eux

machineName='ubuntu-35394-slave'
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