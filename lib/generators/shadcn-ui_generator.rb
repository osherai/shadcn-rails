require "json"
require "pathname"
require "fileutils"
require "rails/generators/base"

class ShadcnUiGenerator < Rails::Generators::Base
  namespace "shadcn-ui"

  attr_reader :component_name, :target_rails_root, :options

  argument :component, required: false, desc: "The name of the component to install"
  argument :rails_root, required: false, desc: "Path to the Rails root directory"

  def self.banner
    "rails generate shadcn-ui <component_name> [--remove] [rails_root_path]"
  end

  def initialize(args, *options)
    super
    @component_name = component
    @target_rails_root = rails_root || Rails.root
    @options = options.first
  end

  def preprocess_sources
    check_target_app
  end

  def install_component
    if component_valid?
      copy_files
    else
      display_available_components
    end
  end

  private

  def check_target_app
    puts "Checking for tailwind..."
    puts "...tailwind found." if check_for_tailwind

    puts "Checking for shadcn.css..."
    check_for_shadcn_css

    puts "Checking for shadcn import..."
    check_for_shadcn_css_import

    puts "Checking for shadcn.tailwind config..."
    check_for_shadcn_tailwind_js

    puts "Checking for component_helper.rb"
    check_for_component_helper
  end

  def available_components
    if !@available_components
      gem_lib_path = File.expand_path("../../lib", __dir__)
      components_file = File.read(File.join(gem_lib_path, "components.json"))
      @available_components = JSON.parse(components_file)
    else
      @available_components
    end
  end

  def display_available_components
    puts self.class.banner
    puts "\nAvailable components:"

    available_components.each do |component, _|
      description = "# A #{component} component"
      banner_line = "rails generate shadcn-ui #{component} #{" " * (20 - component.length)} #{description}"
      puts banner_line
    end
  end

  def copy_files
    return unless component_valid?
    puts "Installing #{component_name} component..."

    install_component_files(component_name)
    component_data["dependencies"]&.each do |dependency|
      if dependency.is_a?(String)
        copy_file(dependency)
      elsif dependency.is_a?(Hash)
        install_component_files(dependency["component"])
      end
    end
    puts "#{component_name.capitalize} component installed!"
  end

  def install_component_files(key)
    return unless component_valid?(key)

    available_components[key]["files"].each do |file|
      copy_file(file)
    end
  end

  def copy_file(file)
    source_path = File.expand_path(File.join("../../", file), __dir__)
    destination_path = File.expand_path(File.join(target_rails_root, file))
    if File.exist?(source_path)
      FileUtils.mkdir_p(File.dirname(destination_path))
      puts "...copying #{file}"
      FileUtils.cp(source_path, destination_path)
    end
  end

  def component_data(name = nil)
    @component_data ||= available_components[component_name]
  end

  def component_valid?(name = nil)
    name ||= component_name
    name.present? && available_components.key?(name) && component_data
  end

  def check_for_tailwind
    return true if tailwind_entrypoint_path

    abort <<~MSG
      shadcn-ui requires Tailwind CSS. Please include tailwindcss-rails in your Gemfile and run `rails tailwindcss:install` to install Tailwind CSS.
      This generator looks for an application stylesheet that includes Tailwind directives. Supported locations include app/assets/tailwind, app/assets/stylesheets, and app/frontend/stylesheets.
    MSG
  end

  def check_for_shadcn_css
    shadcn_file_path = "app/assets/stylesheets/shadcn.css"
    if File.exist?(File.expand_path(File.join(target_rails_root, shadcn_file_path)))
      puts "...found shadcn.css"
      true
    else
      source_path = File.expand_path(File.join("../../", shadcn_file_path), __dir__)
      destination_path = File.expand_path(File.join(target_rails_root, shadcn_file_path))
      puts "...copying shadcn.css to app/assets/stylesheets/shadcn.css"
      FileUtils.cp(source_path, destination_path)
    end
  end

  def check_for_shadcn_css_import
    tailwind_file_path = tailwind_entrypoint_path

    return puts "Tailwind entrypoint not found." unless tailwind_file_path && File.file?(tailwind_file_path)

    matched_file = File.readlines(tailwind_file_path).any? { |s| s.include?("shadcn.css") }
    return if matched_file

    puts "Importing shadcn.css into #{relative_tailwind_entrypoint}..."
    insert_import_first_line(tailwind_file_path, shadcn_import_statement(tailwind_file_path))
  end

  def insert_import_line(file_path, line)
    file_contents = File.read(file_path)
    new_contents = file_contents.gsub(/@tailwind\s+utilities;/, "\\0\n#{line}\n")
    File.write(file_path, new_contents)
  end

  def insert_import_first_line(file_path, line)
    file_contents = File.read(file_path)
    new_contents = "#{line}\n#{file_contents}"
    File.write(file_path, new_contents)
  end

  def check_for_shadcn_tailwind_js
    extension = tailwind_config_extension
    shadcn_tailwind_path = "config/shadcn.tailwind.#{extension}"
    destination_path = File.expand_path(File.join(target_rails_root, shadcn_tailwind_path))

    if File.exist?(destination_path)
      puts "...found #{File.basename(shadcn_tailwind_path)}"
      return true
    end

    source_path = locate_shadcn_tailwind_template(extension)

    unless source_path && File.exist?(source_path)
      puts "Unable to locate shadcn.tailwind template for .#{extension}; skipping copy."
      return
    end

    FileUtils.mkdir_p(File.dirname(destination_path))
    FileUtils.cp(source_path, destination_path)

    puts "...copying #{File.basename(source_path)} to #{shadcn_tailwind_path}"
    puts tailwind_config_integration_message(extension)
  end

  def tailwind_config_extension
    %w[ts mjs cjs js].find do |ext|
      File.exist?(File.expand_path(File.join(target_rails_root, "config/tailwind.config.#{ext}")))
    end || "js"
  end

  def locate_shadcn_tailwind_template(extension)
    preferred_filename = "config/shadcn.tailwind.#{extension}"
    preferred_path = File.expand_path(File.join("../../", preferred_filename), __dir__)

    return preferred_path if File.exist?(preferred_path)

    fallback_filename = case extension
                        when "ts"
                          "config/shadcn.tailwind.ts"
                        when "mjs"
                          "config/shadcn.tailwind.mjs"
                        when "cjs"
                          "config/shadcn.tailwind.cjs"
                        else
                          "config/shadcn.tailwind.js"
                        end

    File.expand_path(File.join("../../", fallback_filename), __dir__)
  end

  def tailwind_config_integration_message(extension)
    case extension
    when "ts"
      "Import and merge the config in your tailwind.config.ts using `import shadcn from './shadcn.tailwind';`."
    when "mjs"
      "Import the config with `import shadcnConfig from './shadcn.tailwind.mjs';` and spread it into your Tailwind config."
    when "cjs"
      "Require the config with `const shadcnConfig = require('./shadcn.tailwind.cjs');` and merge it into module.exports."
    else
      "Require the config with `const shadcnConfig = require('./shadcn.tailwind.js');` and spread it into module.exports."
    end
  end

  def tailwind_entrypoint_path
    return unless (relative_path = tailwind_entrypoint_relative_path)

    File.expand_path(File.join(target_rails_root, relative_path))
  end

  def relative_tailwind_entrypoint
    tailwind_entrypoint_relative_path || "app/assets/tailwind/application.css"
  end

  def tailwind_entrypoint_relative_path
    @tailwind_entrypoint_relative_path ||= begin
      candidate = tailwind_entrypoint_candidates.find do |relative_path|
        File.file?(File.expand_path(File.join(target_rails_root, relative_path)))
      end

      candidate || discover_tailwind_entrypoint
    end
  end

  def tailwind_entrypoint_candidates
    %w[
      app/assets/tailwind/application.css
      app/assets/stylesheets/application.tailwind.css
      app/assets/stylesheets/application.css
      app/assets/stylesheets/application.pcss
      app/assets/stylesheets/application.scss
      app/frontend/stylesheets/application.tailwind.css
      app/frontend/stylesheets/application.css
    ]
  end

  def shadcn_import_statement(tailwind_file_path)
    shadcn_absolute_path = File.expand_path(File.join(target_rails_root, "app/assets/stylesheets/shadcn.css"))
    tailwind_directory = Pathname.new(File.dirname(tailwind_file_path))
    relative_path = Pathname.new(shadcn_absolute_path).relative_path_from(tailwind_directory)
    "@import \"#{relative_path}\";"
  rescue StandardError
    "@import \"shadcn.css\";"
  end

  def discover_tailwind_entrypoint
    search_glob = File.join(target_rails_root, "app", "{assets,frontend}", "**", "*.{css,pcss,scss}")

    Dir.glob(search_glob).find do |absolute_path|
      next unless File.file?(absolute_path)

      begin
        contents = File.read(absolute_path)
      rescue StandardError
        next
      end

      contents.include?("@tailwind")
    end&.yield_self do |absolute_path|
      Pathname.new(absolute_path).relative_path_from(Pathname.new(target_rails_root)).to_s
    end
  end

  def check_for_component_helper
    component_helper_path = "app/helpers/components_helper.rb"
    if File.exist?(File.expand_path(File.join(target_rails_root, component_helper_path)))
      puts "...found components_helper.rb"
      true
    else
      source_path = File.expand_path(File.join("../../", component_helper_path), __dir__)
      destination_path = File.expand_path(File.join(target_rails_root, component_helper_path))
      puts "...copying components_helper.rb app/helpers"

      FileUtils.cp(source_path, destination_path)
    end
  end
end

# Two things - you need the helper helpers
# you have to put @import on the 3rd line after the tailwind directives? Is that possible? It's because of border-border...worse case you can just use the actual styles
