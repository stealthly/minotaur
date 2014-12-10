include_recipe 'docker'

# Pull latest image
docker_image 'kamon/grafana_graphite' do
  action :pull
  retries 3
  retry_delay 10
end

# Run container exposing ports
docker_container 'grafana_graphite' do
  image 'kamon/grafana_graphite'
  detach true
  port ['80:80', '2003:2003', '8125:8125/udp', '8126:8126']
end
