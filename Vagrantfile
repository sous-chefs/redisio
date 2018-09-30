# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'.freeze

base_box         = 'precise32'
url              = 'http://files.vagrantup.com/precise32.box'
cookbooks_path   = ['../', 'cookbooks/']
chef_upgrade     = <<~CMD
  which apt-get > /dev/null 2>&1 && apt-get install curl --yes
  gem install chef --no-rdoc --no-ri
CMD

solo_path        = '/tmp/vagrant-chef-1'.freeze
easy_run_solo    = <<~CMD
  echo 'sudo chef-solo -c #{solo_path}/solo.rb -j #{solo_path}/dna.json' >  /home/vagrant/solo.sh
  chmod 775 /home/vagrant/solo.sh
  chown vagrant:vagrant /home/vagrant/solo.sh
CMD

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.berkshelf.berksfile_path = './Berksfile'
  config.berkshelf.enabled = true

  config.vm.define :redisio do |r|
    r.vm.box     = base_box
    r.vm.box_url = url
    r.vm.network :private_network, ip: '192.168.50.5'
    r.vm.provision :shell, inline: 'sudo apt-get -y install build-essential'
    r.vm.provision :shell, inline: chef_upgrade
    r.vm.provision :shell, inline: easy_run_solo

    r.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = cookbooks_path
      chef.add_recipe 'redisio::default'
      chef.add_recipe 'redisio::enable'
      chef.json = {
        'redisio' => {
          'servers' => [
            {
              'port' => 6379
            }
          ]
        }
      }
    end
  end

  config.vm.define :sentinel do |s|
    s.vm.box     = base_box
    s.vm.box_url = url
    s.vm.network :private_network, ip: '192.168.50.10'
    s.vm.provision :shell, inline: 'sudo apt-get -y install build-essential'
    s.vm.provision :shell, inline: chef_upgrade
    s.vm.provision :shell, inline: easy_run_solo

    s.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = cookbooks_path
      chef.add_recipe 'redisio::sentinel'
      chef.add_recipe 'redisio::sentinel_enable'
      chef.json = {
        'redisio' => {
          'sentinels' => [
            {
              'sentinel_bind' => '0.0.0.0',
              'sentinel_port' => 26379,
              'name' => 'redisio',
              'master_ip' => '192.168.50.5',
              'master_port' => '6379'
            }
          ]
        }
      }
    end
  end
end
