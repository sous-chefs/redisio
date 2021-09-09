# Pulled from the now replaced ulimit cookbook
# TODO: find a more tidy way to do this
ulimit = node['ulimit']

if platform_family?('debian')
  template '/etc/pam.d/su' do
    cookbook ulimit['pam_su_template_cookbook']
  end

  cookbook_file '/etc/pam.d/sudo' do
    cookbook node['ulimit']['ulimit_overriding_sudo_file_cookbook']
    source node['ulimit']['ulimit_overriding_sudo_file_name']
    mode '0644'
  end
end

if ulimit.key?('users')
  ulimit['users'].each do |user, attributes|
    user_ulimit user do
      attributes.each do |a, v|
        send(a.to_sym, v)
      end
    end
  end
end
