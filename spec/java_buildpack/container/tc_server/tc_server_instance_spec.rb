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
require 'java_buildpack/container/tc_server/tc_server_instance'

describe JavaBuildpack::Container::TcServerInstance do
  include_context 'component_helper'

  let(:component_id) { 'tc-server' }

  let(:test_java_home) { { 'JAVA_HOME' => "#{droplet.java_home.root}" } }

  it 'always detects' do
    expect(component.detect).to eq("tc-server-instance=#{version}")
  end

  it 'extracts tc Server from a GZipped TAR',
     app_fixture:   'container_tc_server',
     cache_fixture: 'stub-tc-server.tar.gz' do

    component.compile

    expect(sandbox + 'instance').to exist
  end

  it 'links only the application files and directories to the ROOT webapp',
     app_fixture:   'container_tc_server_with_index',
     cache_fixture: 'stub-tc-server.tar.gz' do

    FileUtils.touch(app_dir + '.test-file')

    component.compile

    root_webapp = sandbox + 'instance/webapps/ROOT'

    web_inf = root_webapp + 'WEB-INF'
    expect(web_inf).to exist
    expect(web_inf).to be_symlink
    expect(web_inf.readlink).to eq((app_dir + 'WEB-INF').relative_path_from(root_webapp))

    index = root_webapp + 'index.html'
    expect(index).to exist
    expect(index).to be_symlink
    expect(index.readlink).to eq((app_dir + 'index.html').relative_path_from(root_webapp))

    expect(root_webapp + '.test-file').not_to exist
  end

  it 'links the Tomcat datasource JAR to the ROOT webapp when that JAR is present',
     app_fixture:   'container_tc_server',
     cache_fixture: 'stub-tc-server-with-datasource-jar.tar.gz' do

    component.compile

    web_inf_lib = app_dir + 'WEB-INF/lib'
    app_jar     = web_inf_lib + 'tomcat-jdbc.jar'
    expect(app_jar).to exist
    expect(app_jar).to be_symlink
    expect(app_jar.readlink).to eq((sandbox + 'instance/lib/tomcat-jdbc.jar').relative_path_from(web_inf_lib))
  end

  it 'does not link the Tomcat datasource JAR to the ROOT webapp when that JAR is absent',
     app_fixture:   'container_tc_server',
     cache_fixture: 'stub-tc-server.tar.gz' do

    component.compile

    app_jar = app_dir + 'WEB-INF/lib/tomcat-jdbc.jar'
    expect(app_jar).not_to exist
  end

  it 'links additional libraries to the ROOT webapp',
     app_fixture:   'container_tc_server',
     cache_fixture: 'stub-tc-server.tar.gz' do

    component.compile

    web_inf_lib = app_dir + 'WEB-INF/lib'

    test_jar_1 = web_inf_lib + 'test-jar-1.jar'
    test_jar_2 = web_inf_lib + 'test-jar-2.jar'
    expect(test_jar_1).to exist
    expect(test_jar_1).to be_symlink
    expect(test_jar_1.readlink).to eq((additional_libs_directory + 'test-jar-1.jar').relative_path_from(web_inf_lib))

    expect(test_jar_2).to exist
    expect(test_jar_2).to be_symlink
    expect(test_jar_2.readlink).to eq((additional_libs_directory + 'test-jar-2.jar').relative_path_from(web_inf_lib))
  end

  context do

    before do |example|
      expect(component).to receive(:shell)
                           .with(%r{tar xzf spec/fixtures/#{example.metadata[:cache_fixture]} -C .* --strip 1 2>&1})
                           .and_call_original
    end

    it 'only applies user-template if all other template requirements are satisfied',
       cache_fixture: 'stub-tc-server.tar.gz' do

      expect(component).to receive(:shell)
                             .with(test_java_home, /--template user-template/, unsetenv_others: true)
                             .and_call_original

      component.compile
    end

    context do

      let(:configuration) { super().merge('templates' => ['additional-template']) }

      it 'applies additionally listed templates if specified',
         cache_fixture: 'stub-tc-server.tar.gz' do

        expect(component).to receive(:shell)
                               .with(test_java_home, /--template additional-template/, unsetenv_others: true)
                               .and_call_original

        component.compile
      end
    end

    context do

      let(:configuration) { super().merge('templates' => ['apr-ssl']) }

      it 'does not apply additionally listed templates if on denied list',
         cache_fixture: 'stub-tc-server.tar.gz' do

        expect(component).not_to receive(:shell)
                                   .with(test_java_home, /--template apr-ssl/, unsetenv_others: true)
                                   .and_call_original

        component.compile
      end
    end

    context do

      before do |example|
        allow(droplet).to receive(:copy_resources) do |target_directory|
          resources = Pathname.new('resources/tc_server')
          FileUtils.cp_r((resources.to_s + '/.'), target_directory) if resources.exist?

          user_template = target_directory + 'templates/user-template'
          FileUtils.rm_rf user_template
          FileUtils.cp_r "spec/fixtures/#{example.metadata[:user_template]}", user_template
        end
      end

      it 'applies buildpack-support-template if no ApplicationStartupFailureDetectingLifecycleListener is specified',
         cache_fixture: 'stub-tc-server.tar.gz',
         user_template: 'user-template-no-buildpack-support' do

        expect(component).to receive(:shell)
                               .with(test_java_home, /--template buildpack-support-template/, unsetenv_others: true)
                               .and_call_original

        component.compile
      end

      it 'applies remote-ip-valve-template if no RemoteIpValve is specified',
         cache_fixture: 'stub-tc-server.tar.gz',
         user_template: 'user-template-no-remote-ip-valve' do

        allow(component).to receive(:shell).and_call_original
        expect(component).to receive(:shell)
                               .with(test_java_home, /--template remote-ip-valve-template/, unsetenv_others: true)
                               .and_call_original

        component.compile
      end

      it 'applies symbolic-links-template if no allowLinking is specified',
         cache_fixture: 'stub-tc-server.tar.gz',
         user_template: 'user-template-no-symbolic-links' do

        allow(component).to receive(:shell).and_call_original
        expect(component).to receive(:shell)
                               .with(test_java_home, /--template symbolic_links_template/, unsetenv_others: true)
                               .and_call_original

        component.compile
      end

    end

  end

end
