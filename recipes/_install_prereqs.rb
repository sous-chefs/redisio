packages_to_install = case node['platform_family']
                      when 'debian'
                        %w(
                          libssl-dev tar
                        )
                      when 'rhel', 'fedora'
                        %w(
                          openssl-devel tar
                        )
                      else
                        %w()
                      end

packages_to_install.each do |pkg|
  package pkg do
    action :install
  end
end
