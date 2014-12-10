# Small wrapper around inserting lines to files

define :insert_if_no_match, :data => nil, :owner => 'root', :group => 'root', :mode => 0644, :action => :insert do

	file params[:name] do
		owner params[:owner]
		group params[:group]
		mode params[:mode]
	end

	unless params[:data].to_s.empty? then
		ruby_block "Insert data into #{params[:name]}" do
			block do
				file = Chef::Util::FileEdit.new("#{params[:name]}")
				data = Regexp.escape("#{params[:data]}")
				file.insert_line_if_no_match("#{data}", params[:data])
				file.write_file
			end
		end
	end

end