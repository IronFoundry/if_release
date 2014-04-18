require 'yaml'
require 'pathname'

class String
  def to_ruby_path(end_slash=false)
    "#{'/' if self[0]=='\\'}#{self.split('\\').join('/')}#{'/' if end_slash}" 
  end 
end

dea_yml_file = ARGV[0]
ruby_path = Pathname.new(ARGV[1])
ironfoundry_path = Pathname.new(ARGV[2])
output_file = Pathname.new(ARGV[3])

File.open(dea_yml_file, 'r') do |file|
    config = YAML.load(file)
    
    config['dea_ruby'] = (ruby_path + 'ruby.exe').to_s.to_ruby_path
    config['pid_filename'] = (ironfoundry_path + 'run/dea_ng.pid').to_s.to_ruby_path
    config['base_dir'] = (ironfoundry_path + 'dea_ng').to_s.to_ruby_path
    config['warden_socket'] = 'tcp://localhost:4444'
    config['directory_server']['logging']['file'] = (ironfoundry_path + 'log/directory_server.log').to_s.to_ruby_path
    config['directory_server']['logging'].delete('syslog')
    config['logging']['file'] = (ironfoundry_path + 'log/dea_ng.log').to_s.to_ruby_path
    config['logging'].delete('syslog')
    config['staging']['environment']['BUILDPACK_CACHE'] = (ironfoundry_path + 'buildpack_cache').to_s.to_ruby_path
    config['bind_mounts'] =[ 'src_path' => (ironfoundry_path + 'buildpack_cache').to_s ]
    config['stacks'] = ['windows2012']
    config['instance']['cpu_limit_shares'] = 256 # this was needed for v161

    File.open(output_file, 'w') do |file|
        file.write(YAML.dump(config))
    end
end

