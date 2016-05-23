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

require 'spec_helper'
require 'component_helper'
require 'fileutils'
require 'java_buildpack/container/tc_server'
require 'java_buildpack/container/tc_server/tc_server_insight_support'
require 'java_buildpack/container/tc_server/tc_server_instance'
require 'java_buildpack/container/tc_server/tc_server_lifecycle_support'
require 'java_buildpack/container/tc_server/tc_server_logging_support'
require 'java_buildpack/container/tc_server/tc_server_access_logging_support'
require 'java_buildpack/container/tc_server/tc_server_redis_store'

describe JavaBuildpack::Container::TcServer do
  include_context 'component_helper'

  let(:component) { StubTcServer.new context }

  let(:configuration) do
    { 'tc_server'              => tc_server_configuration,
      'lifecycle_support'      => lifecycle_support_configuration,
      'logging_support'        => logging_support_configuration,
      'access_logging_support' => access_logging_support_configuration,
      'redis_store'            => redis_store_configuration }
  end

  let(:tc_server_configuration) { double('tc-server-configuration') }

  let(:lifecycle_support_configuration) { double('lifecycle-support-configuration') }

  let(:logging_support_configuration) { double('logging-support-configuration') }

  let(:access_logging_support_configuration) { double('access-logging-support-configuration') }

  let(:redis_store_configuration) { double('redis-store-configuration') }

  it 'detects WEB-INF',
     app_fixture: 'container_tc_server' do

    expect(component.supports?).to be
  end

  it 'does not detect when WEB-INF is absent',
     app_fixture: 'container_main' do

    expect(component.supports?).not_to be
  end

  it 'does not detect when WEB-INF is present in a Java main application',
     app_fixture: 'container_main_with_web_inf' do

    expect(component.supports?).not_to be
  end

  it 'creates submodules' do
    expect(JavaBuildpack::Container::TcServerInstance)
    .to receive(:new).with(sub_configuration_context(tc_server_configuration))
    expect(JavaBuildpack::Container::TcServerLifecycleSupport)
    .to receive(:new).with(sub_configuration_context(lifecycle_support_configuration))
    expect(JavaBuildpack::Container::TcServerLoggingSupport)
    .to receive(:new).with(sub_configuration_context(logging_support_configuration))
    expect(JavaBuildpack::Container::TcServerAccessLoggingSupport)
    .to receive(:new).with(sub_configuration_context(access_logging_support_configuration))
    expect(JavaBuildpack::Container::TcServerRedisStore)
    .to receive(:new).with(sub_configuration_context(redis_store_configuration))
    expect(JavaBuildpack::Container::TcServerInsightSupport).to receive(:new).with(context)

    component.sub_components context
  end

  it 'returns command' do
    expect(component.release).to eq('test-var-2 test-var-1 JAVA_HOME=$PWD/.test-java-home JAVA_OPTS="test-opt-2 ' \
                                    'test-opt-1 -Dhttp.port=$PORT" exec $PWD/.java-buildpack/tc_server/instance/bin/' \
                                    'catalina.sh run')
  end

end

class StubTcServer < JavaBuildpack::Container::TcServer

  public :command, :sub_components, :supports?

end

def sub_configuration_context(configuration)
  c                 = context.clone
  c[:configuration] = configuration
  c
end
