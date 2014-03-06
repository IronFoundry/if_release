require 'yaml'
require 'pathname'

default_yml_file = Pathname.new(ARGV[0])
output_file = Pathname.new(ARGV[1])
shared_secret = ARGV[2]
router_address = ARGV[3]
cloudfoundry_domain = ARGV[4]
nats_address = ARGV[5]

File.open(default_yml_file, 'r') do |file|
    config = YAML.load(file)
    
    config['nats_servers'] = ["nats://nats:#{shared_secret}@#{nats_address}:4222"]
    config['domain'] = cloudfoundry_domain
    config['loggregator']['router'] = "#{router_address}:3456"
    config['loggregator']['shared_secret'] = shared_secret

    File.open(output_file, 'w') do |file|
        file.write(YAML.dump(config))
    end
end

