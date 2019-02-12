# to make sure the jenkins node is created before the other nodes, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

config_jenkins_fqdn = 'jenkins.example.com'
config_jenkins_ip   = '10.10.10.100'
# Slaves params
config_ubuntu_61630_slave_fqdn  = "ubuntu-61630-slave.#{config_jenkins_fqdn}"
config_ubuntu_61630_slave_ip    = '10.10.10.170'
config_ubuntu_fqdn  = "ubuntu-slave.#{config_jenkins_fqdn}"
config_ubuntu_ip    = '10.10.10.101'
config_windows_fqdn = "windows.#{config_jenkins_fqdn}"
config_windows_ip   = '10.10.10.102'


# link to the gitlab-vagrant environment.
config_gitlab_fqdn  = 'gitlab.example.com'
config_gitlab_ip    = '10.10.9.99'

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-18.04-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.memory = 2048
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    # lv.nested = true
    lv.keymap = 'pt'
    lv.random :model => 'random'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.cpus = 2
    vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
  end

  config.vm.define :jenkins do |config|
    config.vm.hostname = config_jenkins_fqdn
    config.vm.network :private_network, ip: config_jenkins_ip, libvirt__forward_mode: 'route', libvirt__dhcp_enabled: false
    config.vm.provision :shell, inline: "echo '#{config_ubuntu_ip} #{config_ubuntu_fqdn}' >>/etc/hosts"
    config.vm.provision :shell, inline: "echo '#{config_windows_ip} #{config_windows_fqdn}' >>/etc/hosts"
    config.vm.provision :shell, inline: "echo '#{config_gitlab_ip} #{config_gitlab_fqdn}' >>/etc/hosts"
    config.vm.provision :shell, path: 'provision-mailhog.sh'
    config.vm.provision :shell, path: 'provision.sh'
    config.vm.provision :shell, path: 'provision-example-jobs.sh'
    config.vm.provision :shell, path: 'provision-example-test-jenkins-gitlab-plugin.sh'
    config.vm.provision :reload
    config.vm.provision :shell, path: 'provision-summary.sh'
  end



  config.vm.define :ubuntu_61630_slave do |config|
    config.vm.hostname = config_ubuntu_61630_slave_fqdn
    config.vm.network :private_network, ip: config_ubuntu_61630_slave_ip, libvirt__forward_mode: 'route', libvirt__dhcp_enabled: false
    config.vm.provision :shell, inline: "echo '#{config_jenkins_ip} #{config_jenkins_fqdn}' >>/etc/hosts"
    config.vm.provision :shell, inline: "echo '#{config_gitlab_ip} #{config_gitlab_fqdn}' >>/etc/hosts"
    config.vm.provision :shell, path: 'provision-ubuntu.sh'
  end
  config.vm.define :ubuntu_slave do |config|
    config.vm.hostname = config_ubuntu_fqdn
    config.vm.network :private_network, ip: config_ubuntu_ip, libvirt__forward_mode: 'route', libvirt__dhcp_enabled: false
    config.vm.provision :shell, inline: "echo '#{config_jenkins_ip} #{config_jenkins_fqdn}' >>/etc/hosts"
    config.vm.provision :shell, inline: "echo '#{config_gitlab_ip} #{config_gitlab_fqdn}' >>/etc/hosts"
    config.vm.provision :shell, path: 'provision-ubuntu.sh'
  end


  config.vm.define :windows do |config|
    config.vm.provider :libvirt do |lv, config|
      lv.memory = 4096
      config.vm.synced_folder '.', '/vagrant', type: 'smb', smb_username: ENV['USER'], smb_password: ENV['VAGRANT_SMB_PASSWORD']
    end
    config.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    config.vm.box = 'windows-2019-amd64'
    config.vm.hostname = 'windows'
    config.vm.network :private_network, ip: config_windows_ip, libvirt__forward_mode: 'route', libvirt__dhcp_enabled: false
    config.vm.provision :shell, inline: "echo '#{config_jenkins_ip} #{config_jenkins_fqdn}' | Out-File -Encoding ASCII -Append c:/Windows/System32/drivers/etc/hosts"
    config.vm.provision :shell, inline: "echo '#{config_gitlab_ip} #{config_gitlab_fqdn}' | Out-File -Encoding ASCII -Append c:/Windows/System32/drivers/etc/hosts"
    config.vm.provision :shell, inline: "$env:chocolateyVersion='0.10.11'; iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex", name: "Install Chocolatey"
    config.vm.provision :shell, path: 'windows/ps.ps1', args: 'provision-dotnet.ps1'
    config.vm.provision :reload
    config.vm.provision :shell, path: 'windows/ps.ps1', args: 'provision-base.ps1'
    config.vm.provision :shell, path: 'windows/ps.ps1', args: 'provision-vs-build-tools.ps1'
    config.vm.provision :shell, path: 'windows/ps.ps1', args: 'provision-dotnetcore-sdk.ps1'
    config.vm.provision :shell, path: 'windows/ps.ps1', args: 'provision-enable-long-paths.ps1'
    config.vm.provision :shell, path: 'windows/ps.ps1', args: ['provision-jenkins-slave.ps1', config_jenkins_fqdn, config_windows_fqdn]
  end


  config.trigger.before :up do |trigger|
    trigger.only_on = 'jenkins'
    trigger.run = {
      inline: '''bash -euc \'
certs=(
  ../windows-domain-controller-vagrant/tmp/ExampleEnterpriseRootCA.der
  ../gitlab-vagrant/tmp/gitlab.example.com-crt.der
  ../gitlab-vagrant/tmp/gitlab-jenkins-impersonation-token.txt
)
for cert_path in "${certs[@]}"; do
  if [ -f $cert_path ]; then
    mkdir -p tmp
    cp $cert_path tmp
  fi
done
\'
'''
    }
  end


  config.trigger.after :up do |trigger|
    trigger.only_on = [/ubuntu*/, 'windows']
    trigger.run = {inline: "vagrant ssh -c 'cat /vagrant/tmp/*.ssh_known_hosts | sudo tee /etc/ssh/ssh_known_hosts' jenkins"}
    #trigger.run = path: 'addSlave.sh'
  end
end
