require 'tilt'
require 'callsite'

# Top-level Renee constant
class Renee
  # This module is responsible for handling the rendering of templates
  # using Tilt supporting all included template engines.
  module Render
    ##
    # Exception responsible for when a generic rendering error occurs.
    #
    class RenderError < RuntimeError; end

    ##
    # Exception responsible for when an expected template does not exist.
    #
    class TemplateNotFound < RenderError; end

    # Same as render but automatically halts.
    # @param  (see #render)
    # @return (see #render)
    # @see #render
    def render!(*args, &blk)
      halt render(*args, &blk)
    end

    def render_inline!(*args, &blk)
      args << Callsite.parse(caller.first)
      halt render_inline(*args, &blk)
    end

    ##
    # Renders a string given the engine and the content.
    #
    # @param [Symbol] engine The template engine to use for rendering.
    # @param [String] data The content or file to render.
    # @param [Hash] options The rendering options to pass onto tilt.
    #
    # @return [String] The result of rendering the data with specified engine.
    #
    # @example
    #  render :haml, "%p test" # => "<p>test</p>"
    #  render :haml, :index    # => "<p>test</p>"
    #  render "index"          # => "<p>test</p>"
    #
    # @api public
    #
    def render(*args, &block)
      render_setup(args, block) do |engine, data, options, views|
        template_cache.fetch(engine, data, options) do
          file_path, engine = find_template(views, data, engine)
          template = Tilt[engine]
          raise TemplateNotFound, "Template engine not found: #{engine}" if template.nil?
          raise TemplateNotFound, "Template '#{data}' not found in '#{engine}'!"  unless file_path
          # TODO suppress errors for layouts?
          template.new(file_path, 1, options)
        end
      end
    end # render

    def render_inline(*args, &block)
      call_data = args.last.is_a?(Callsite::Line) ? args.pop : Callsite.parse(caller.first)
      path, line = call_data.filename, call_data.line
      render_setup(args, block) do |engine, data, options, views|
        body = data.is_a?(String) ? Proc.new { data } : data
        template = Tilt[engine]
        raise "Template engine not found: #{engine}" if template.nil?
        template.new(path, line.to_i, options, &body)
      end
    end

    def render_setup(args, block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      data = args.pop
      engine = args.pop
      engine &&= engine.to_sym

      options                    ||= {}
      options[:outvar]           ||= '@_out_buf'
      options[:default_encoding] ||= settings.default_encoding || options[:encoding] || "utf-8"

      locals         = options.delete(:locals) || {}
      views          = options.delete(:views)  || settings.views_path || "./views"
      layout         = options.delete(:layout)
      layout_engine  = options.delete(:layout_engine) || engine
      # TODO suppress template errors for layouts?
      # TODO allow content_type to be set with an option to render?
      scope          = options.delete(:scope) || self

      # TODO default layout file convention?
      template       = yield(engine, data, options, views)
      output         = template.render(scope, locals, &block)

      if layout # render layout
        # TODO handle when layout is missing better!
        options = options.merge(:views => views, :layout => false, :scope => scope)
        return render(layout_engine, layout, options.merge(:locals => locals)) { output }
      end
      output
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