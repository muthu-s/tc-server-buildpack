# tc Server Container
The tc Server Container allows servlet 2 and 3 web applications to be run.  These applications are run as the root web application in a tc Server container.

<table>
  <tr>
    <td><strong>Detection Criterion</strong></td>
    <td>Existence of a <tt>WEB-INF/</tt> folder in the application directory and <a href="container-java_main.md">Java Main</a> not detected</td>
  </tr>
  <tr>
    <td><strong>Tags</strong></td>
    <td><tt>tc-server-instance=&lang;version&rang;</tt>, <tt>tc-server-lifecycle-support=&lang;version&rang;</tt>, <tt>tc-server-logging-support=&lang;version&rang;</tt> <tt>tc-server-redis-store=&lang;version&rang;</tt> <i>(optional)</i></td>
  </tr>
</table>
Tags are printed to standard output by the buildpack detect script

If the application uses Spring, [Spring profiles][] can be specified by setting the [`SPRING_PROFILES_ACTIVE`][] environment variable. This is automatically detected and used by Spring. The Spring Auto-reconfiguration Framework will specify the `cloud` profile in addition to any others.

## Configuration
For general information on configuring the buildpack, including how to specify configuration values through environment variables, refer to [Configuration and Extension][].

The container can be configured by modifying the [`config/tc_server.yml`][] file in the buildpack fork.  The container uses the [`Repository` utility support][repositories] and so it supports the [version syntax][] defined there.

| Name | Description
| ---- | -----------
| `access_logging_support.repository_root` | The URL of the tc Server Access Logging Support repository index ([details][repositories]).
| `access_logging_support.version` | The version of tc Server Access Logging Support to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tomcat-access-logging-support/index.yml).
| `access_logging_support.access_logging` | Set to `enabled` to turn on the access logging support. Default is `disabled`.
| `gemfire_store.gemfire.repository_root` | The URL of the GemFire repository index ([details][repositories]).
| `gemfire_store.gemfire.version` | The version of GemFire to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/gem-fire/index.yml).
| `gemfire_store.gemfire_logging.repository_root` | The URL of the GemFire Logging repository index ([details][repositories]).
| `gemfire_store.gemfire_logging.version` | The version of GemFire Logging to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/slf4j-jdk14/index.yml).
| `gemfire_store.gemfire_logging_api.repository_root` | The URL of the GemFire Logging API repository index ([details][repositories]).
| `gemfire_store.gemfire_logging_api.version` | The version of GemFire Logging API to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/slf4j-api/index.yml).
| `gemfire_store.gemfire_modules.repository_root` | The URL of the GemFire Modules repository index ([details][repositories]).
| `gemfire_store.gemfire_modules.version` | The version of GemFire Modules to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/gem-fire-modules/index.yml).
| `gemfire_store.gemfire_modules_tomcat7.repository_root` | The URL of the GemFire Modules Tomcat 7 repository index ([details][repositories]).
| `gemfire_store.gemfire_modules_tomcat7.version` | The version of GemFire Modules Tomcat 7 to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/gem-fire-modules-tomcat7/index.yml).
| `gemfire_store.gemfire_security.repository_root` | The URL of the GemFire Security repository index ([details][repositories]).
| `gemfire_store.gemfire_security.version` | The version of GemFire Security to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/gem-fire-security/index.yml).
| `lifecycle_support.repository_root` | The URL of the tc Server Lifecycle Support repository index ([details][repositories]).
| `lifecycle_support.version` | The version of tc Server Lifecycle Support to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tomcat-lifecycle-support/index.yml).
| `logging_support.repository_root` | The URL of the tc Server Logging Support repository index ([details][repositories]).
| `logging_support.version` | The version of tc Server Logging Support to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tomcat-logging-support/index.yml).
| `redis_store.connection_pool_size` | The Redis connection pool size.  Note that this is per-instance, not per-application.
| `redis_store.database` | The Redis database to connect to.
| `redis_store.repository_root` | The URL of the Redis Store repository index ([details][repositories]).
| `redis_store.timeout` | The Redis connection timeout (in milliseconds).
| `redis_store.version` | The version of Redis Store to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/redis-store/index.yml).
| `tc_server.repository_root` | The URL of the tc Server repository index ([details][repositories]).
| `tc_server.templates` | An array of template names to be applied to all instances (e.g. `diagnostics` or `async-logger`).  The additional templates will be applied, in order, after the `user-template`.  Some of the templates in tc Server will not work in Cloud Foundry and therefore will be excluded.  If one of these templates is listed a warning will be shown and the template ignored.  The templates that are excluded are `apr-ssl`, `bio-ssl`, `cluster-node`, `elastic-memory`, `jmx-ssl`, and `nio-ssl`.
| `tc_server.version` | The version of tc Server to use. Candidate versions can be found in [this listing](http://download.pivotal.io.s3.amazonaws.com/tc-server/index.yml).

### Additional Resources
The container can also be configured by overlaying a set of resources on the default distribution.  To do this, add files to a template in the `resources/tc_server/template` directory or create a new template in the buildpack fork. If new templates have been added they must be configured in the `tc_server.templates` property as described in the [Configuration](#Configuration) section. For example, to override the default `logging.properties` modify the `resources/tc_server/templates/user-template/conf/logging.properties` file. Three templates are provided to aid configuring a custom template, they all duplicate configuration in the default `user-template` so there is no point using them in conjunction with it. They are designed to integrate other templates in to the Cloud Foundry environment.

#### Buildpack Support Template

This configures Tomcat to use Cloud Foundry integrated Logging. This includes Access logging if it is enabled in the `config/tomcat.yml` file and application startup failure detection. This template will make Tomcats logging output available to view on the command line and from calls to `cf logs [--recent]`.

#### Remote IP Valve Template

This template enables the remote IP valve in the `server.xml` file with the following configuration. ` <Valve className="org.apache.catalina.valves.RemoteIpValve" protocolHeader="x-forwarded-proto"/>`

#### Symbolic Links Template

This template sets `allowLinking='true'` in the `context.xml` files context definition element.

### Supported tc Server templates

These can be listed by name in the `tc_server.templates` configuration as described in the [Configuration](#Configuration) section.

| Name | Usage
| ---- | -----
| ajp | Adds an Apache JServ Protocol (AJP) connector.
| apr | Adds an APR/native (APR) connector for HTTP and an APRLifecycleListener to detect the APR-based native library required to use the APR/native connector.
| async-logger | Adds asynchronous logging.
| bio | Adds a Blocking IO (BIO) connector for HTTP.
| diagnostics | Adds a JDBC resource that integrates with request diagnostics to report slow queries and a ThreadDiagnosticsValve at the Engine level to report slow running requests.
| gemfire-cs | This module provides fast, scalable, and reliable client/server HTTP session replication for tc Server.
| gemfire-p2p | This module provides fast, scalable, and reliable peer to peer HTTP session replication for tc Server.
| nio | Adds a Non-Blocking IO (NIO) connector for HTTP.

## Session Replication
By default, the tc Server instance is configured to store all Sessions and their data in memory.  Under certain cirmcumstances it my be appropriate to persist the Sessions and their data to a repository.  When this is the case (small amounts of data that should survive the failure of any individual instance), the buildpack can automatically configure tc Server to do so by binding an appropriate service.

### Redis
To enable Redis-based session replication, simply bind a Redis service containing a name, label, or tag that has `session-replication` as a substring.

### GemFire
To enable GemFire-based session replication, simply bind a [Session State Caching (SSC) GemFire service][] containing a name, label, or tag that has `session_replication` as a substring. GemFire services intended to be used for session replication will automatically have a tag of 'session_replication'.

## Managing Entropy
Entropy from `/dev/random` is used heavily to create session ids, and on startup for initializing SecureRandom, which can then cause instances to fail to start in time (See the [Tomcat Wiki]). Also, the entropy is shared so it's possible for a single app to starve the DEA of entropy and cause apps in other containers that make use of entropy to be blocked.
If this is an issue then configuring `/dev/urandom` as an alternative source of entropy should help. It is unlikely, but possible, that this may cause some security issues which should be taken in to account.

Example in a manifest.yml
```
env:
  JAVA_OPTS: -Djava.security.egd=file:///dev/urandom
```

## Supporting Functionality
Additional supporting functionality can be found in the [`java-buildpack-support`][] Git repository.

[Configuration and Extension]: ../README.md#configuration-and-extension
[`config/tc_server.yml`]: ../config/tc_server.yml
[Session State Caching (SSC) GemFire service]: https://network.pivotal.io/products/p-ssc-gemfire
[`java-buildpack-support`]: https://github.com/cloudfoundry/java-buildpack-support
[repositories]: extending-repositories.md
[Spring profiles]:http://blog.springsource.com/2011/02/14/spring-3-1-m1-introducing-profile/
[`SPRING_PROFILES_ACTIVE`]: http://docs.spring.io/spring/docs/4.0.0.RELEASE/javadoc-api/org/springframework/core/env/AbstractEnvironment.html#ACTIVE_PROFILES_PROPERTY_NAME
[version syntax]: extending-repositories.md#version-syntax-and-ordering
