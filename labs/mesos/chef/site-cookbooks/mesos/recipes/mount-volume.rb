# Recipe for mounting volume to specific mount point
#

# Creating directories up to mount point
directory "#{node[:mesos][:mount_point]}" do
  owner node[:current_user]
  mode "0755"
  recursive true
end

# Creating file system for volume label, device id pair
execute 'mkfs' do
  command "mkfs -t ext3 -F -L #{node[:mesos][:volume_label]} #{node[:mesos][:device_id]}"
  # only if it's not mounted already
  not_if "dumpe2fs #{node[:mesos][:device_id]}"
end

# Adding to fstab
execute 'fstab-add' do
  command "echo \"/dev/disk/by-label/#{node[:mesos][:volume_label]} #{node[:mesos][:mount_point]} ext3 defaults 0 2\" >> /etc/fstab"
  # if not there yet
  not_if "grep ^/dev/disk/by-label/#{node[:mesos][:volume_label]} /etc/fstab"
end

# Mounting
mount "#{node[:mesos][:mount_point]}" do
  device node[:mesos][:device_id]
  fstype 'ext3'
  options 'noatime,nobootwait'
  action [:enable, :mount]
end
