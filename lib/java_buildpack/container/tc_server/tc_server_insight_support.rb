# Encoding: utf-8
# Cloud Foundry Java Buildpack
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
require 'java_buildpack/component/base_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tc_server/tc_server_utils'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for tc Server Spring Insight support.
    # DO NOT DEPEND ON THIS
    class TcServerInsightSupport < JavaBuildpack::Component::BaseComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::BaseComponent#detect)
      def detect
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        link_to(container_libs_directory.children, tc_server_lib) if container_libs_directory.exist?
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
      end

      private

      def container_libs_directory
        @droplet.root + '.spring-insight/container-libs'
      end
    end

  end
end
