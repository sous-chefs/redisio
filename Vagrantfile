# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define :redisio do |r|
    r.vm.box = "precise32"
    r.vm.box_url = "http://files.vagrantup.com/precise32.box"

    r.vm.provision :shell do |s|
      s.inline = %Q{
        which apt-get > /dev/null 2>&1 && apt-get install curl --yes
        gem install chef --no-rdoc --no-ri
      }
    end

    r.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = ["../","cookbooks/"]
      chef.add_recipe "redisio::default"
      chef.add_recipe "redisio::enable"
      chef.json = {
        'redisio' => {
          'servers' => [
            {'name' => 'myredis', 'port' => 6379}
          ]
        }
      }
    end

  end

  #config.vm.provision :chef_solo do |chef|
    #chef.cookbooks_path = "../"
    #chef.roles_path = "../my-recipes/roles"
    #chef.data_bags_path = "../my-recipes/data_bags"
    #chef.add_recipe "mysql"
    #chef.add_role "web"
    #chef.json = { :mysql_password => "foo" }
  #end
end
