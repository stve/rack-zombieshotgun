module Rack
  
  ##
  # Rack middleware for protecting against Windows zombie attacks.
  #
  # According to the The Zombie Survival Guide [1], there are better ways
  # to protect yourself from Zombies, shotguns not being at top of the list. 
  # That  said, this middleware might not be the best tool either, but like 
  # shotguns, it should be fun. And that's the point!
  # 
  # When zombie attack conditions are met, issues a head not found response, 
  # meaning no body, with a 404 status. Poetry.
  # 
  # [1] http://en.wikipedia.org/wiki/The_Zombie_Survival_Guide
  #
  # === Options:
  #
  #   :agents         Toggle agent kills by passing false. Default is true.
  #   :directories    Toggle directory kills by passing false. Default is true.
  #   :formats        Toggle format kills by passing false.  Defaults to true.
  class ZombieShotgun
    
    ZOMBIE_AGENTS = [
      /FrontPage/,
      /Microsoft Office Protocol Discovery/,
      /Microsoft Data Access Internet Publishing Provider/
    ].freeze

    ZOMBIE_DIRS = ['_vti_bin','MSOffice','verify-VCNstrict','notified-VCNstrict'].to_set.freeze
    
    ZOMBIE_FORMATS = ['cgi', 'aspx', 'asp', 'ico'].to_set.freeze
    
    attr_reader :options, :request, :agent
    
    def initialize(app, options={})
      @app, @options = app, {
        :agents => true,
        :directories => true,
        :formats => true
      }.merge(options)
    end
    
    def call(env)
      @agent = env['HTTP_USER_AGENT']
      @request = Rack::Request.new(env)
      zombie_attack? ? head_not_found : @app.call(env)
    end
    
    
    private
    
    def head_not_found
      [404, {"Content-Length" => "0"}, []]
    end

    def zombie_attack?
      zombie_dir_attack? || zombie_agent_attack? || zombie_format_attack?
    end

    def zombie_dir_attack?
      path = request.path_info
      options[:directories] && ZOMBIE_DIRS.any? { |dir| path.include?("/#{dir}/") }
    end

    def zombie_agent_attack?
      options[:agents] && agent && ZOMBIE_AGENTS.any? { |za| agent =~ za }
    end
    
    def zombie_format_attack?
      format = ::File.extname(request.path_info)
      unless format.empty?
        format = format[1, format.length-1]
        options[:formats] && ZOMBIE_FORMATS.any? { |zf| zf == format }
      end
    end
    
  end
end


