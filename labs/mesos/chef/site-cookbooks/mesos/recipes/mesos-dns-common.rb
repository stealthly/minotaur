# Recipe for mesos-dns common resolv.conf update
#

# Insert new local dns nameserver in the top of resolv.conf
ruby_block "insert_line" do
  block do
    file = Chef::Util::FileEdit.new("/etc/resolvconf/resolv.conf.d/head")
    file.insert_line_if_no_match("/nameserver 127.0.0.1/", "nameserver 127.0.0.1")
    file.write_file
  end
end

# Update resolv.conf file
bash 'resolvconf' do
  user 'root'
  code 'resolvconf -u'
end
