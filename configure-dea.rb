require 'yaml'
require 'pathname'

dea_yml_file = ARGV[0]
ruby_path = Pathname.new(ARGV[1])
ironfoundry_path = Pathname.new(ARGV[2])
output_file = ironfoundry_path + 'dea_ng/app/config/dea.yml'

File.open(dea_yml_file, 'r') do |file|
    config = YAML.load(file)
    
    config['dea_ruby'] = (ruby_path + 'ruby.exe').to_s
    config['pid_filename'] = (ironfoundry_path + 'run/dea_ng.pid').to_s
    config['base_dir'] = (ironfoundry_path + 'dea_ng').to_s
    config['warden_socket'] = 'tcp://localhost:4444'
    config['directory_server']['logging']['file'] = (ironfoundry_path + 'log/directory_server.log').to_s
    config['directory_server']['logging'].delete('syslog')
    config['logging']['file'] = (ironfoundry_path + 'log/dea_ng.log').to_s
    config['logging'].delete('syslog')
    config['staging']['environment']['BUILDPACK_CACHE'] = (ironfoundry_path + 'buildpack_cache').to_s
    config['staging']['environment']['PATH'] = ruby_path.to_s
    config['bind_mounts'] =[ 'src_path' => (ironfoundry_path + 'buildpack_cache').to_s ]
    config['stacks'] = ['mswin-clr']

    File.open(output_file, 'w') do |file|
        file.write(YAML.dump(config))
    end
end

