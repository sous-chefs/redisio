packages_to_install = case node['platform']
                      when 'debian', 'ubuntu'
                        %w(
                          tar
                        )
                      when 'redhat', 'centos', 'fedora', 'scientific', 'suse', 'amazon', 'rocky'
                        %w(
                          tar
                        )
                      else
                        %w()
                      end

packages_to_install.each do |pkg|
  package pkg do
    action :install
  end
end
