require 'tilt'
require 'callsite'

# Top-level Renee constant
class Renee
  # This module is responsible for handling the rendering of templates
  # using Tilt supporting all included template engines.
  module Render
    ##
    # Exception responsible for when an expected template does not exist.
    #
    class TemplateNotFound < RuntimeError; end

    # Same as render but automatically halts.
    # @param  (see #render)
    # @return (see #render)
    # @see #render
    def render!(file, engine = nil, options = nil, &blk)
      halt render(file, engine, options, &blk)
    end

    # Same as inline but automatically halts.
    # @param  (see #inline)
    # @return (see #inline)
    # @see #inline
    def inline!(data, engine, options = {}, &blk)
      options[:_caller] = Callsite.parse(caller.first)
      halt inline(data, engine, options, &blk)
    end

    ##
    # Renders a file given the engine and the content.
    #
    # @param [String] file The path to the file to render
    # @param [Symbol] engine The name of the engine to use to render the content. If this isn't specified
    # it will be detected based on the extension of the file.
    # @param [Hash] options The options to pass in for rendering.
    #
    # @return [String] The result of rendering the data with specified engine.
    #
    # @example
    #  render "index", :haml   # => "<p>test</p>"
    #  render "index"          # => "<p>test</p>"
    #
    # @api public
    #
    def render(file, engine = nil, options = nil, &block)
      options, engine = engine, nil if engine.is_a?(Hash)
      render_setup(engine, options, block) do |view_options, views|
        template_cache.fetch(engine, file, view_options) do
          file_path, found_engine = find_template(views, file, engine)
          template = Tilt[found_engine]
          raise TemplateNotFound, "Template engine not found: #{found_engine.inspect}" unless template
          raise TemplateNotFound, "Template #{file.inspect} (with engine #{engine.inspect}) not found in #{views.inspect}!" unless file_path
          # TODO suppress errors for layouts?
          template.new(file_path, 1, view_options)
        end
      end
    end # render

    ##
    # Renders a string given the engine and the content.
    #
    # @param [String] data The string data to render.
    # @param [Symbol] engine The name of the engine to use to render the content. If this isn't specified
    # it will be detected based on the extension of the file.
    # @param [Hash] options The options to pass in for rendering.
    #
    # @return [String] The result of rendering the data with specified engine.
    #
    # @example
    #  inline "%p test", :haml # => "<p>test</p>"
    #
    # @api public
    #
    def inline(data, engine, options = nil, &block)
      options, engine = engine, nil if engine.is_a?(Hash)
      call_data = options.delete(:_caller) || Callsite.parse(caller.first)
      render_setup(engine, options, block) do |view_options, views|
        body = data.is_a?(Proc) ? data : Proc.new { data }
        template = Tilt[engine]
        raise "Template engine not found: #{engine}" if template.nil?
        template.new(call_data.filename, call_data.line, view_options, &body)
      end
    end

    private
    def render_setup(engine, options, block)
      options                    ||= {}
      options[:outvar]           ||= '@_out_buf'
      options[:default_encoding] ||= settings.default_encoding || options[:encoding] || "utf-8"

      locals         = options.delete(:locals) || {}
      views          = options.delete(:views)  || settings.views_path || "./views"
      layout         = options.delete(:layout)
      layout_engine  = options.delete(:layout_engine)
      # TODO suppress template errors for layouts?
      # TODO allow content_type to be set with an option to render?
      scope          = options.delete(:scope) || self

      # TODO default layout file convention?
      template       = yield(options, views)
      output         = template.render(scope, locals, &block)

      if layout # render layout
        # TODO handle when layout is missing better!
        options = options.merge(:views => views, :layout => false, :scope => scope)
        render(layout, layout_engine, options.merge(:locals => locals)) { output }
      else
        output
      end
    end

    ##
    # Searches view paths for template based on data and engine with rendering options.
    # Supports finding a template without an engine.
    #
    # @param [String] views The view paths
    # @param [String] name The name of the template
    # @param [Symbol] engine The engine to use for rendering.
    #
    # @return [<String, Symbol>] An array of the file path and the engine.
    #
    # @example
    #  find_template("./views", "index", :erb) => ["path/to/index.erb", :erb]
    #  find_template("./views", "foo")         => ["path/to/index.haml", :haml]
    #
    # @api private
    #
    def find_template(views, name, engine=nil)
      lookup_ext = (engine || File.extname(name.to_s)[1..-1] || "*").to_s
      base_name = name.to_s.chomp(".#{lookup_ext}")
      file_path = Dir[File.join(views, "#{base_name}.#{lookup_ext}")].first
      engine ||= File.extname(file_path)[1..-1].to_sym if file_path
      [file_path, engine]
    end # find_template

    # Maintain Tilt::Cache of the templates.
    def template_cache
      @template_cache ||= Tilt::Cache.new
    end
  end
end