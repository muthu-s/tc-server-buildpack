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

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/container/tc_server/gemfire/gemfire_modules'

describe JavaBuildpack::Container::GemFireModules do
  include_context 'component_helper'

  let(:component_id) { 'tc-server' }

  it 'always detects' do
    expect(component.detect).to eq("gem-fire-modules=#{version}")
  end

  it 'copies resources',
     cache_fixture: 'stub-gemfire-modules.jar' do

    component.compile

    expect(sandbox + "instance/lib/gemfire-modules-#{version}.jar").to exist
  end

  it 'does nothing during release' do
    component.release
  end

end
