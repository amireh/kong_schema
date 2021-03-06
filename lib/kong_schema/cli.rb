require 'gli'
require 'tty-prompt'
require 'pastel'

require_relative './schema'
require_relative './reporter'

module KongSchema
  class CLI
    include GLI::App

    def run(argv)
      program_desc 'Configure Kong from file.'

      version KongSchema::VERSION

      sort_help :manually

      flag([ 'c', 'config' ], {
        desc: 'Path to the configuration file (in place of the first argument.)',
        arg_name: 'FILE'
      })

      desc 'Apply configuration from a .yml or .json file.'
      arg(:config_file)
      command :up do |c|
        c.flag([ 'c', 'config' ], {
          desc: 'Path to the configuration file (in place of the first argument.)',
          arg_name: 'FILE'
        })

        c.flag([ 'k', 'key' ], {
          default_value: 'kong',
          desc: 'The root configuration property key.',
          arg_name: 'NAME'
        })

        c.flag([ 'f', 'format' ], {
          default_value: 'json',
          desc: 'Format to use for reporting objects. Either "json" or "yaml".',
          long_desc: 'Available formats: "json" or "yaml".',
          arg_name: 'FORMAT',
          must_match: %w(json yaml)
        })

        c.switch([ 'quiet' ], {
          default_value: false,
          desc: 'Do not print changes to be applied'
        })

        c.switch([ 'diff' ], {
          default_value: true,
          desc: 'Print diffs of objects (before and after changes)'
        })

        c.switch([ 'confirm' ], {
          default_value: true,
          desc: 'Prompt for confirmation before applying changes.'
        })

        c.action do |globals, options, args|
          filepath = resolve_config_file!(args: args, globals: globals, options: options)

          up(filepath: filepath, options: options)
        end
      end

      desc 'Reset Kong configuration completely.'
      arg(:config_file)
      command :down do |c|
        c.flag([ 'k', 'key' ], {
          default_value: 'kong',
          desc: 'The root configuration property key.',
          arg_name: 'NAME'
        })

        c.switch([ 'confirm' ], {
          default_value: true,
          desc: 'Prompt for confirmation before applying changes.'
        })

        c.action do |globals, options, args|
          filepath = resolve_config_file!(args: args, globals: globals, options: options)

          down(filepath: filepath, options: options)
        end
      end

      super(argv)
    end

    private

    def up(filepath:, options:)
      pastel = Pastel.new
      schema = KongSchema::Schema
      config = read_property(load_file(filepath), options[:key])

      schema.scan(config).tap do |changes|
        if changes.empty?
          puts "#{green('✓')} Nothing to update."
        else
          unless options[:quiet]
            puts KongSchema::Reporter.report(changes,
              object_format: options[:format].to_sym,
              diff: options[:diff]
            )
          end

          if !options[:confirm] || yes?('Commit the changes to Kong?')
            schema.commit(config, changes)

            puts "#{green('✓')} Kong has been reconfigured!"
          end
        end
      end
    end

    def down(filepath:, options:)
      pastel = Pastel.new
      schema = KongSchema::Schema
      config = read_property(load_file(filepath), options[:key])

      if !options[:confirm] || yes?("You are about to completely reset Kong's database. Proceed?")
        KongSchema::Client.purge(config)

        puts "#{green('✓')} Kong reset."
      end
    end

    def resolve_config_file!(args:, globals:, options:)
      filepath = args.first || options[:config] || globals[:config]

      if filepath.nil?
        bail! "Missing path to .yml or .json config file"
      else
        filepath
      end
    end

    def load_file(filepath)
      if filepath.end_with?('.json')
        JSON.parse(File.read(filepath))
      else
        YAML.load_file(filepath)
      end
    end

    def read_property(config, key)
      if key.to_s.empty?
        config
      else
        config.fetch(key.to_s)
      end
    end

    def yes?(message, default: false)
      TTY::Prompt.new.yes?(message, default: default, color: false)
    end

    def red(text)
      pastel.red(text)
    end

    def green(text)
      pastel.green(text)
    end

    def pastel
      @pastel ||= Pastel.new
    end

    def bail!(reason)
      help_now! red("✘ #{reason}")
    end
  end
end
