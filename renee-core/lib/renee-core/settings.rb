class Renee
  class Core
    ##
    # Stores configuration settings for a particular Renee application.
    # Powers the Renee setup block which is instance eval'ed into this object.
    #
    # @example
    #  Renee::Core.new { ... }.setup { views_path "./views" }
    #
    class Settings
      attr_reader :includes, :variable_types
      def initialize
        @includes = []
        @variable_types = {}
        register_variable_type :integer, IntegerMatcher
        register_variable_type :int, :integer
      end

      # Get or sets the views_path for an application.
      #
      # @param [String] path The path to the view files.
      #
      # @example
      #  views_path("./views") => nil
      #  views_path => "./views"
      #
      # @api public
      def views_path(path = nil)
        path ? @views_path = path : @views_path
      end

      # Module(s) to include into the base application.
      # @param [Module] mods Modules to include.
      def include(*mods)
        mods.each { |mod| includes << mod }
      end

      def register_variable_type(name, matcher)
        matcher = case matcher
        when Matcher then matcher
        when Array   then Matcher.new(matcher.map{|m| @variable_types[m]})
        when Symbol  then @variable_types[matcher]
        else              Matcher.new(matcher)
        end
        matcher.name = name
        @variable_types[name] = matcher
      end
    end
  end
end