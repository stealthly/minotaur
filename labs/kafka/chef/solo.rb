require 'chef/version_constraint'

file_cache_path    "/var/chef/cache"
file_backup_path   "/var/chef/backup"
cookbook_path   [ "/deploy/repo/labs/kafka/chef/cookbooks", "/deploy/repo/labs/kafka/chef/site-cookbooks" ]
data_bag_path   "/deploy/repo/labs/kafka/chef/data_bags"

log_level :info
verbose_logging    false

encrypted_data_bag_secret nil

http_proxy nil
http_proxy_user nil
http_proxy_pass nil
https_proxy nil
https_proxy_user nil
https_proxy_pass nil
no_proxy nil

if Chef::VersionConstraint.new("< 11.8.0").include?(Chef::VERSION)
  role_path nil
else
  role_path []
end

Chef::Config.ssl_verify_mode = :verify_none
