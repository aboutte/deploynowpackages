#
# Cookbook Name:: deploynowpackages
# Recipe:: default
#
# Copyright 2017, REAN CLOUD
#
# All rights reserved - Do Not Redistribute
#

# Download and untar/unzip the specified package in the /tmp/deploynow/cookbooks dir
node["deploynowpackages"]["packages"].each do |package|

  unless package.is_a? Hash
    raise "REAN Deploy : Package [#{package}] is required to be a hash"
  end

  if not package.has_key? "download_url"
    raise "REAN Deploy : Package [#{package}] has no 'download_url'"
  end

  if not package.has_key? "zip_file_name"
    raise "REAN Deploy : Package [#{package}] has no 'zip_file_name'"
  end

 
  if not package.has_key? "unzipped_name"
    raise "REAN Deploy : Package [#{package}] has no 'unzipped_name'"
  end

  if not package.has_key? "package_name"
    raise "REAN Deploy : Package [#{package}] has no 'package_name'"
  end
 
	actual_download_url = ""
	if platform?('windows')
		directory node['deploynowpackages']['packages_home_win'] do
			mode '0755'
			action :create
		end
		package_download_file = "#{node['deploynowpackages']['packages_home_win']}#{package['zip_file_name']}"
		actual_download_url = package['download_url']
	else
		directory node['deploynowpackages']['packages_home_linux'] do
			mode '0755'
			action :create
		end
		package_download_file = "#{node['deploynowpackages']['packages_home_linux']}#{package['zip_file_name']}"
		actual_download_url = package['download_url']
	end

	if package['private_access_token'] != "null" 
        http = actual_download_url.split('://')[0]
		repo_url = actual_download_url.split('://')[1]
		rewrite_url="#{http}://#{package['private_access_token']}@#{repo_url}"
	else
	   rewrite_url = actual_download_url
	end

	if package['private_access_token'] != "null" and node['platform'] != 'windows'
		bash 'download_archive' do
            code <<-EOH
            curl -u #{package['private_access_token']}:x-oauth-basic -sL #{actual_download_url} >  #{package_download_file}
                EOH
        end
	else
		remote_file package_download_file do
			source rewrite_url
			mode '0755'
		end
	end

	if platform?('windows')
		powershell_script 'unzip package' do
  		code <<-EOH
	 			cd #{node["deploynowpackages"]["packages_home_win"]}
				tar -zxf #{package['zip_file_name']}
				mv #{package['unzipped_name']} #{package['package_name']}
	  		EOH
		end	

		
	else
		bash 'extract_package' do
			code <<-EOH
				cd #{node["deploynowpackages"]["packages_home_linux"]}
				tar -zxf #{package['zip_file_name']}
				mv #{package['unzipped_name']} #{package['package_name']}
			EOH
		end
	end
end
