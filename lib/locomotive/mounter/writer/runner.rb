module Locomotive
  module Mounter
    module Writer

      class Runner

        attr_accessor :kind, :parameters, :mounting_point

        def initialize(kind)
          self.kind = kind

          # avoid to load all the ruby files at the startup, only when we need it
          base_dir = File.join(File.dirname(__FILE__), kind.to_s)
          require File.join(base_dir, 'base.rb')
          Dir[File.join(base_dir, '*.rb')].each { |lib| require lib }
        end

        # Write the data of a mounting point instance to a target folder
        #
        # @param [ Hash ] parameters The parameters. It should contain the mounting_point and target_path keys.
        #
        def run!(parameters = {})
          self.parameters = parameters.symbolize_keys

          self.mounting_point = self.parameters.delete(:mounting_point)

          self.prepare

          self.write_all
        end

        # Before starting to write anything
        # Can be defined by writer runners
        def prepare
        end

        # List of all the writers
        #
        # @return [ Array ] List of the writer classes
        #
        def writers
          raise Locomotive::Mounter::ImplementationIsMissingException.new("[#{self.kind}] Writers are missing")
        end

        # Execute all the writers
        def write_all
          only = parameters[:only].try(:map) do |name|
            "#{name}_writer".camelize
          end.try(:insert, 0, 'SiteWriter')

          begin
            self.writers.each do |klass|
              next if only && !only.include?(klass.name.demodulize)
              writer = klass.new(self.mounting_point, self)
              writer.prepare
              writer.write
            end
          rescue Exception => e
            Locomotive::Mounter.logger.error e.backtrace
            puts "\n\nBlocking Error: #{e.message.colorize(:red)}"
          end
        end

      end

    end
  end
end