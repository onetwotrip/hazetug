require 'hazetug/config'
require 'hazetug/compute'
require 'hazetug/ui'
require 'hazetug/tug'
require 'hazetug/net_ssh'
require 'chef/mash'

class Hazetug
  class Haze
    include Hazetug::UI::Mixin
    include Hazetug::NetSSH::Mixin

    attr_reader :config, :compute_name

    RE_BITS  = /-?x(32)$|-?x(64)$|(32)bit|(64)bit/i

    def initialize(config={})
      @compute_name = Hazetug.leaf_klass_name(self.class)
      @compute = Hazetug::Compute.const_get(compute_name).new
      @config  = configure(config)
      @server  = nil
      @ready   = false
    end

    def provision
      provision_server
      wait_for_ssh
    rescue Fog::Errors::Error
      # Catch fog errors, don't abort further execution
      ui.error "[#{compute_name}] #{$!.inspect}"
    rescue
      # For unknown exceptions, notify and exit
      ui.error "[#{compute_name}] #{$!.inspect}"
      ui.msg $@
      exit(1)
    end

    def ready?
      @ready
    end

    def public_ip_address
    end

    def private_ip_address
    end

    # Update hash with haze access settings only if any available
    def update_access_settings(hash)
      {
        compute_name: compute_name.downcase,
        public_ip_address: (public_ip_address || 
            (server and server.ssh_ip_address)),
        private_ip_address: private_ip_address
      }.inject(hash) do |hsh, (k, v)|
        hsh[k] = v if v
        hsh
      end
    end

    class << self
      def requires(*args)
        args.empty? ? @requires : @requires = args.flatten.dup
      end

      def defaults(hash=nil)
        hash.nil? ? @defaults : @defaults = hash
      end

      def [](haze_name)
        klass = Hazetug.camel_case_name(haze_name)
        Hazetug::Haze.const_get(klass)
      end
    end

    protected
    attr_accessor :server
    attr_reader   :compute

    def provision_server
      ui.error "#{compute_name} Provisioning is not impemented"
    end

    def wait_for_ssh
      ui.error "#{compute_name} Waiting for shh is not impemented"
    end

    private

    def configure(config)
      input = config.keys.map(&:to_sym)
      requires = self.class.requires

      unless (norequired = requires.select {|r| not input.include?(r)}).empty?
        ui.error "Required options missing: #{norequired.join(', ')}"
        raise ArgumentError, "Haze options missing"
      end

      Mash.new(self.class.defaults.merge(config))
    end

  end
end