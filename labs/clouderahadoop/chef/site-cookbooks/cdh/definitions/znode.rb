# This is a DSL wrapper around creating and getting
# znodes and their content on zookeeper server

define :znode, :action => :create, :server => nil, :destination => nil, :content => nil, :expect => nil, :retries => 0, :retry_delay => 2, :fail_on_retry => true do
  require 'zookeeper' 

  server = node[:hadoop][:zk_servers][:ips].sample
  znode = params[:name]
  content = params[:content]
  expect = params[:expect]
  destination = params[:destination]

  done = false
  remaining_retries = params[:retries]
  retry_delay = params[:retry_delay]
  fail_on_retry = params[:fail_on_retry]
  fail_msg = "Failed to execute #{params[:action]} for znode #{znode}"

  begin
    z = Zookeeper.new("#{server}:2181")

    case params[:action]
    when :create
      z.create(:path => "#{znode}")
      Chef::Log.info ("Created znode #{znode}")
      done = true

    when :set
      z.set(:path => "#{znode}", :data => "#{content}")
      Chef::Log.info ("znode \'#{znode}\' content set to \'#{content}\'")
      done = true

    when :get
      znode_content = z.get(:path => "#{znode}")[:data]
      unless znode_content.to_s.empty?
        Chef::Log.info ("Got content #{znode_content} for znode #{znode}")
        if content.to_s.empty? or content.to_s == znode_content.to_s
          destination.update( {"content" => "#{znode_content}"} )
          done = true
        else
          Chef::Log.info ("Expecting content: #{content}, got: #{znode_content}")
        end
      end

    when :get_children
      children = z.get_children(:path => "#{znode}")[:children]
      if not children.to_s.empty?
        Chef::Log.info ("Got children #{children} for znode #{znode}")
        for item in children
          destination.update( {"#{item}" => true} )
        end
        done = true
      end

    when :expect
      znode_content = z.get(:path => "#{znode}")[:data]
      unless znode_content.to_s.empty?
        Chef::Log.info ("Got content #{znode_content} for znode #{znode}")
        if content.to_s == znode_content.to_s
          done = true
        else
          Chef::Log.info ("Expecting content: #{content}, got: #{znode_content}")
        end
      end

    when :delete
      z.delete(:path => "#{znode}")
      Chef::Log.info ("Deleted znode #{znode}")
      done = true

    when :nothing
      done = true
    end

    remaining_retries -= 1

    if !done and remaining_retries > 0 then
      Chef::Log.info ("#{fail_msg}, retrying in #{retry_delay}s, retries left: #{remaining_retries}")
      sleep retry_delay
    elsif !done and fail_on_retry then
      fail RuntimeError, "#{fail_msg}, giving up"
    elsif !done
      Chef::Log.info ("#{fail_msg}, skipping")
      done = true
    end

    z.close

  end while remaining_retries > 0 and done == false
  
end # define
