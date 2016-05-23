# Encoding: utf-8
# Cloud Foundry tc Server Buildpack
# Copyright 2013-2016 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tc_server/tc_server_utils'
require 'java_buildpack/logging/logger_factory'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for the tc Server instance.
    class TcServerInstance < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        super(context)
        @logger = JavaBuildpack::Logging::LoggerFactory.get_logger TcServerInstance
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download(@version, @uri) { |file| instantiate file }
        link_to(@application.root.children, root)
        @droplet.additional_libraries << tomcat_datasource_jar if tomcat_datasource_jar.exist?
        @droplet.additional_libraries.link_to web_inf_lib
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        true
      end

      private

      EXCLUDED_TEMPLATES = %w(ajp apr-ssl bio-ssl cluster-node elastic-memory jmx-ssl nio-ssl).freeze

      def additional_templates
        command   = []
        templates = @configuration['templates']

        if templates
          templates.each do |template|
            if EXCLUDED_TEMPLATES.include? template
              @logger.warn { "Template #{template} is not supported.  It will be ignored during instance creation." }
            else
              command << ['--template', template]
            end
          end
        end

        command
      end

      def build_command(root)
        command = [
          root + 'tcruntime-instance.sh',
          'create', INSTANCE_NAME,
          '--instance-directory', @droplet.sandbox,
          '--layout', 'combined',
          '--template', 'user-template'
        ]

        unless server_configuration_has? root, /ApplicationStartupFailureDetectingLifecycleListener/
          command << %w(--template buildpack-support-template)
        end

        command << %w(--template remote-ip-valve-template) unless server_configuration_has? root, /RemoteIpValve/
        command << %w(--template symbolic_links_template) unless context_configuration_has? root, /allowLinking/
        command << additional_templates

        command.flatten
      end

      def configuration_has?(configurations, matcher)
        configurations.any? { |configuration| configuration.open('r') { |f| f.read =~ matcher } }
      end

      def context_configuration_has?(root, matcher)
        configuration_has? Pathname.glob(root + 'templates/user-template/conf/context*.xml'), matcher
      end

      def create_instance(tmpdir)
        shell({ 'JAVA_HOME' => @droplet.java_home.root.to_s }, build_command(tmpdir).join(' '), unsetenv_others: true)
      end

      def instantiate(file)
        with_timing "Instantiating tc Server in #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          Dir.mktmpdir do |tmpdir|
            tmpdir = Pathname.new(tmpdir)
            prepare_installation(file, tmpdir)
            create_instance(tmpdir)
          end

          FileUtils.rm_f tc_server_instance_directory + 'bin/setenv.sh'
          FileUtils.rm_rf tc_server_instance_directory + 'webapps'
        end
      end

      def prepare_installation(file, tmpdir)
        FileUtils.mkdir_p @droplet.sandbox
        shell "tar xzf #{file.path} -C #{tmpdir} --strip 1 2>&1"

        @droplet.copy_resources tmpdir
      end

      def root
        tc_server_webapps + 'ROOT'
      end

      def server_configuration_has?(root, matcher)
        configuration_has? Pathname.glob(root + 'templates/user-template/conf/server*.xml'), matcher
      end

      def tomcat_datasource_jar
        tc_server_lib + 'tomcat-jdbc.jar'
      end

      def web_inf_lib
        @droplet.root + 'WEB-INF/lib'
      end

    end

  end
end
