# resource.build.agent.windows

This repository contains the code used to build a base Windows build agent on a Hyper-V VM hard disk. The current process
will use the Windows Server 2016 Core base image, i.e. without UI, on to create a [Jenkins build agent](https://jenkins.io)
with the [swarm plugin](https://plugins.jenkins.io/swarm).

## Image

### Contents

The current process will use the [Windows 2016 Core base image](https://github.com/Calvinverse/base.vm.windows) and ammending
it using a [Chef](https://www.chef.io/chef/) cookbook which installs the Java
Development Kit, Jenkins, Jolokia and the build tools for .NET and Javascript builds.

### Configuration

* The GIT install. The version of which is determined by the `default['git']['version']`
  attribute in the `default.rb` attributes file in the cookbook.
* The OpenJDK Java development kit which is requried to run Jenkins. The version of which is determined
  by the version of the `java` cookbook in the `metadata.rb` file.
* The [Jenkins swarm slave](https://plugins.jenkins.io/swarm) JAR file. The version of which is determined by the `default['jenkins']['version']`
  attribute in the `default.rb` attributes file in the cookbook.
* The [Jolokia](https://jolokia.org/) JAR file which is used to collect metrics from Jenkins. The
  version of which is determined by the `default['jolokia']['version']` attribute in the `default.rb`
  attributes file in the cookbook.
* The latest .NET build tools.
* The Node, NPM and Yarn tools. The versions of which are determined by the `default['nodesjs']['version']`, `default['npm']['version']` and `default['yarn']['version']`
  attributes in the `default.rb` attributes file in the cookbook.
* The NuGet command line. The version of which is determined by the `default['nuget']['version']`
  attribute in the `default.rb` attributes file in the cookbook.

### Provisioning

During provisioning the standard steps are taken. In addition the Jenkins agent workspace directory permissions are reset as those are lost during the sysprep.

### Logs

Logs are collected via the [Filebeat](https://github.com/pvandervelde/filebeat.mqtt) application
which will normally write the logs to disk. If the Consul-Template service has been provided with
the appropriate credentials then it will generate additional configuration for the syslog service
that allows the logs to be pushed to a RabbitMQ exchange. The [vhost](https://www.rabbitmq.com/vhosts.html)
the log messages are pushed to is determined by the Consul Key-Value key at
`config/services/queue/logs/file/vhost`. The are pushed to the MQTT endpoint for that
vhost which should redirect to the appropriate queues.

### Metrics

Metrics are collected through different means.

* Metrics for Consul are collected by Consul sending [StatsD](https://www.vaultproject.io/docs/internals/telemetry.html)
  metrics to [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/).
* Metrics for Unbound are collected by Telegraf pulling the metrics.
* System metrics, e.g. CPU, disk, network and memory usage, are collected by Telegraf.
* Metrics for Jenkins and the JVM via [Jolokia](https://jolokia.org/) and
[Telegraf](https://www.influxdata.com/time-series-platform/telegraf/).

## Build, test and release

The build process follows the standard procedure for
[building Calvinverse images](https://www.calvinverse.net/documentation/how-to-build).

### Hyper-V

For building Hyper-V images use the following command line

    msbuild entrypoint.msbuild /t:build /P:ShouldCreateHypervImage=true /P:RepositoryArchive=PATH_TO_ARTIFACTLOCATION

where `PATH_TO_ARTIFACTLOCATION` is the full path to the directory where the base image artifact
file is stored.

In order to run the smoke tests on the generated image run the following command line

    msbuild entrypoint.msbuild /t:test /P:ShouldCreateHypervImage=true

## Deploy

TBD
