require 'yaml'
require 'pathname'
require 'optparse'

class Pathname
    def to_windows_path
        self.to_s.gsub('/', '\\')
    end   
end

def parse_args(args)
    options = {}

    opt_parser = OptionParser.new do |opts|
        opts.on('--source-config PATH') do |v|
            options[:source_config] = Pathname.new(v)
        end

        opts.on('--ruby-path PATH') do |v|
            options[:ruby_path] = Pathname.new(v)
        end

        opts.on('--ironfoundry-path PATH') do |v|
            options[:ironfoundry_path] = Pathname.new(v)
        end

        opts.on('--output PATH') do |v|
            options[:output_path]  = Pathname.new(v)
        end

        opts.on('--memory-mb VALUE', Integer) do |v|
            options[:memory_mb] = v
        end

        opts.on('--memory-overcommit-factor VALUE', Integer) do |v|
            options[:memory_overcommit_factor] = v
        end

        opts.on('--disk-mb VALUE', Integer) do |v|
            options[:disk_mb] = v
        end

        opts.on('--disk-overcommit-factor VALUE', Integer) do |v|
            options[:disk_overcommit_factor] = v
        end
    end

    opt_parser.parse!(args)
    options
end

options = parse_args(ARGV)

dea_yml_file = options[:source_config]
ruby_path = options[:ruby_path]
ironfoundry_path = options[:ironfoundry_path]
output_file = options[:output_path] || ironfoundry_path.join('dea_ng/config/dea.yml').expand_path

File.open(dea_yml_file, 'r') do |file|
    config = YAML.load(file)
    
    config['dea_ruby'] = ruby_path.join('ruby.exe').expand_path.to_s
    config['pid_filename'] = ironfoundry_path.join('run/dea_ng.pid').expand_path.to_s
    config['base_dir'] = ironfoundry_path.join('dea_ng').expand_path.to_s
    config['warden_socket'] = 'tcp://localhost:4444'
    config['directory_server']['logging']['file'] = ironfoundry_path.join('log/directory_server.log').expand_path.to_s
    config['directory_server']['logging'].delete('syslog')
    config['logging']['file'] = ironfoundry_path.join('log/dea_ng.log').expand_path.to_s
    config['logging'].delete('syslog')
    config['staging']['environment']['BUILDPACK_CACHE'] = ironfoundry_path.join('buildpack_cache').expand_path.to_s
    config['staging']['environment']['PATH'] = ruby_path.expand_path.to_windows_path
    config['bind_mounts'] =[ 'src_path' => ironfoundry_path.join('buildpack_cache').expand_path.to_windows_path ]
    config['stacks'] = ['windows2012']

    # Optional overrides, if not specified the value will be copied from the source config
    if options.has_key?(:memory_mb)
        config['resources']['memory_mb'] = options[:memory_mb]
    end

    if options.has_key?(:memory_overcommit_factor)
        config['resources']['memory_overcommit_factor'] = options[:memory_overcommit_factor]
    end

    if options.has_key?(:disk_mb)
        config['resources']['disk_mb'] = options[:disk_mb]
    end

    if options.has_key?(:disk_overcommit_factor)
        config['resources']['disk_overcommit_factor'] = options[:disk_overcommit_factor]
    end

    File.open(output_file, 'w') do |file|
        file.write(YAML.dump(config))
        puts "Wrote config file to '#{output_file.to_s}'"
    end
end

