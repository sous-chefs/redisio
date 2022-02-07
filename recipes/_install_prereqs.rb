packages_to_install = case node['platform_family']
                      when 'debian'
                        %w(
                          tar
                        )
                      when 'rhel', 'fedora'
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
