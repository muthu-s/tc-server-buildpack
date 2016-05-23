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

require 'java_buildpack/component/modular_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tc_server/tc_server_insight_support'
require 'java_buildpack/container/tc_server/tc_server_instance'
require 'java_buildpack/container/tc_server/tc_server_lifecycle_support'
require 'java_buildpack/container/tc_server/tc_server_logging_support'
require 'java_buildpack/container/tc_server/tc_server_access_logging_support'
require 'java_buildpack/container/tc_server/tc_server_redis_store'
require 'java_buildpack/container/tc_server/tc_server_gemfire_store'
require 'java_buildpack/container/tc_server/tc_server_utils'
require 'java_buildpack/util/qualify_path'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for tc Server applications.
    class TcServer < JavaBuildpack::Component::ModularComponent
      include JavaBuildpack::Container
      include JavaBuildpack::Util

      protected

      # (see JavaBuildpack::Component::ModularComponent#command)
      def command
        @droplet.java_opts.add_system_property 'http.port', '$PORT'

        [
          @droplet.environment_variables.as_env_vars,
          @droplet.java_home.as_env_var,
          @droplet.java_opts.as_env_var,
          'exec',
          qualify_path(tc_server_instance_directory + 'bin/catalina.sh', @droplet.root),
          'run'
        ].flatten.compact.join(' ')
      end

      # (see JavaBuildpack::Component::ModularComponent#sub_components)
      def sub_components(context)
        [
          TcServerInstance.new(sub_configuration_context(context, 'tc_server')),
          TcServerLifecycleSupport.new(sub_configuration_context(context, 'lifecycle_support')),
          TcServerLoggingSupport.new(sub_configuration_context(context, 'logging_support')),
          TcServerAccessLoggingSupport.new(sub_configuration_context(context, 'access_logging_support')),
          TcServerRedisStore.new(sub_configuration_context(context, 'redis_store')),
          TcServerGemfireStore.new(sub_configuration_context(context, 'gemfire_store')),
          TcServerInsightSupport.new(context)
        ]
      end

      # (see JavaBuildpack::Component::ModularComponent#supports?)
      def supports?
        web_inf? && !JavaBuildpack::Util::JavaMainUtils.main_class(@application)
      end

      private

      def web_inf?
        (@application.root + 'WEB-INF').exist?
      end

    end

  end
end
