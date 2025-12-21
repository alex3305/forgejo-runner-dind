<h3 align="center">
  <img src="assets/forgejo-animated.png" alt="Forgejo" width="100">
  <br/><br/>
  Forgejo runner 🚢 <i>all-in-one</i>
</h3>

<h4 align="center">
  Container image that combines Forgejo Runner 🏃 with an embedded container runtime 🐳.
</h4>

<br/>

## Introduction

At the start of 2025, I switched from [Gitea](https://about.gitea.com/) to [Forgejo](https://forgejo.org/). While Gitea - and its predecessor [Gogs](https://gogs.io/) - are great tools, I appreciate that Forgejo powers its own real-world, public-facing setup with [Codeberg](https://codeberg.org/). And that it has more frequent stable releases.

When I used Gitea Actions, their Docker-in-Docker image with Gitea Act Runner made things super easy. Despite perhaps a few quirks, it’s a great way to get started. Forgejo didn’t have a similar all-in-one image. Their official [forgejo/runner repository](https://code.forgejo.org/forgejo/runner) includes [examples with multiple containers](https://code.forgejo.org/forgejo/runner/src/branch/main/examples/docker-compose), which work fine, but I preferred something simpler.

So, I built this container as a straightforward starting point: a single image for running Forgejo Actions with an embedded container runtime.

### Features

- An **all-in-one Forgejo Runner** with Docker in Docker or Podman image
- **S6 Overlay** for service management
- Periodic Docker pruning
- **Hosted tool cache** support
- **Rootless** for improved security
- Supports **amd64** and **arm64** architectures

## Usage

Getting started is the easiest with Docker Compose. To get started you'll need an already running Forgejo instance with:

- A Forgejo Instance URL (preferably https)
- A Forgejo Actions Registration Token

### Quick Start with Compose

This is a quick start setup with default configuration.

```yaml
services:
  forgejo-runner:
    container_name: forgejo-runner-dind
    image: alex3305/forgejo-runner-dind:latest
    restart: on-failure:5
    privileged: true
    volumes:
      - ~/forgejo-runner:/config
      - cache:/home/rootless/.cache/actcache
      - toolcache:/home/rootless/.cache/toolcache
      - docker:/home/rootless/.local/share/docker
    environment:
      FORGEJO_INSTANCE_URL: https://forgejo.example.com
      FORGEJO_REGISTRATION_TOKEN: JLcy4PhU8wMBmt2mpu5BmW1OqDVlojtPzmQl9mdC
      CONFIG_FILE

volumes:
  cache:
    name: forgejo-runner-cache

  toolcache:
    name: forgejo-runner-tool-cache

  docker:
    name: forgejo-runner-docker-cache
```

> [!NOTE]
> Privileged mode is required for Docker in Docker to function properly. This is explained in [docker-library/docker#151](https://github.com/docker-library/docker/issues/151#issuecomment-483185972) and [docker-library/docker#281](https://github.com/docker-library/docker/issues/281#issuecomment-744766015). However this is still a security issue thats need to treated appropriately.

## Configuration

This section contains the required setup configuration. For usage and more advanced configuration see below.

### Environment variables

A quick overview of the available environment variables.

| Variable                     | Required |               Default               |
| ---------------------------- | :------: | :---------------------------------: |
| `FORGEJO_INSTANCE_URL`       |    ☑️    |                                     |
| `FORGEJO_REGISTRATION_TOKEN` |    ☑️    |                                     |
| `LOG_LEVEL`                  |    ☑️    |               `info`                |
| `FORGEJO_RUNNER_NAME`        |    ❌    |             _hostname_              |
| `CONFIG_FILE`                |    ❌    |                                     |
| `DOCKER_HOST`                |    ❌    | `unix:///run/user/1000/docker.sock` |
| `FORGEJO_RUNNER_LABELS`      |    ❌    |                                     |
| `EXTRA_ARGS`                 |    ❌    |                                     |

> [!IMPORTANT]
> The variables marked with an ☑️ are required until the Forgejo Runner is successfully registered. This can be validated by the `.runner` file that the Forgejo Runner created in the mounted `/config` directory.

#### Forgejo Instance URL

This is the instance URL of Forgejo that must be reachable by the runner.

#### Forgejo Registration Token

The registration token is used to register Forgejo Runner to Forgejo. This works as an authentication and authorization token. This token can be found under `/admin/actions/runners` on your Forgejo instance.

> [!NOTE]
> After registration, the Forgejo Instance URL and Registration Token will be stored in a `/config/.runner` file. After this file is created, the provided environment variables will not be used.

#### Forgejo Runner name

You can provide a custom Forgejo Runner name. This defaults to the hostname of the container. You can also customize the containers hostname to customize this value.

#### Config file

When no config file is provided, the container uses either `/config/config.yml` or `/config/config.yaml` for configuration.

#### Docker host

This is the Unix socket to the Docker daemon. This value can be modified but is highly discouraged.

> [!DANGER]
> IF this value is set incorrectly the container will fail to start.

#### Log Level

The general log level where applicable. This can be adjusted for testing or when the Docker daemon is too verbose.

Allowed values: `debug`, `info`, `warn`, `error`, `fatal`

#### Forgejo Runner Labels

Forgejo Runner labels that are used for workflows. These can also be defined within the configuration file. For more information see the [Choosing Labels section](https://forgejo.org/docs/latest/admin/actions/#choosing-labels) within the Forgejo Actions administrator guide. 

#### Extra args

Optional additional arguments for the Forgejo runner.

Failing to do so may lead to unexpected results. For instance in jobs not starting or unable to access the Docker daemon within a job.

### Configuration file

It is a highly recommended to use a configuration file. It is possible to generate a fresh configuration file with this Docker image using a run command:

```bash
docker run --rm -it \
           --entrypoint forgejo-runner \
           alex3305/forgejo-runner-dind:latest \
           generate-config > config.yaml
```

This will create an 'empty' `config.yaml` file in your current directory. This file can later be mounted in the container.

#### Required configuration variables

Within the configuration file it is required for the following options to be set:

```yaml
container:
  privileged: true
  docker_host: "automount"
```

Failure to do so will make this image fail to start up or function.

## Caching

Caching is setup within the Configuration file. The most basic, functional setup is:

```yaml
cache:
  enabled: true
  dir: "/home/rootless/.cache/actcache"
  host: "forgejo-runner"
```

The host attribute is very important here. This should be either:

1. The hostname or IP address of your runner container if it is reachable from the outside, ie. host or vlan networking
2. The hostname of your container if your container is not reachable from the outside, ie. in a Swarm network

Either way this address must be reachable and routable from the workflows container within dind.

Whenever you want to use option 2 with a hostname, I would recommend setting this value using Docker Compose:

```yaml
services:
  forgejo-runner:
    image: alex3305/forgejo-runner-dind:latest
    privileged: true
    hostname: my-personal-forgejo-runner
    network:
      internal:
    volumes:
      ~/forgejo-runner:/config
```

and setting an identical value in your configuration file:

```yaml
cache:
  enabled: true
  dir: "/home/rootless/.cache/actcache"
  host: "my-personal-forgejo-runner"
```

### Hosted tool cache

It is also possible to use a hosted tool cache. With a hosted tool cache all the workflows can use a shared environment for tooling such as Java, Python or dotnet. This can greatly reduce build times. To use a hosted tool cache configure the following within your configuration file:

```yaml
container:
  options: "-v /home/rootless/.cache/toolcache:/opt/hostedtoolcache"
  valid_volumes: [
    "/home/rootless/.cache/toolcache",
    "/opt/hostedtoolcache",
  ]
```

I also opt to mount this path to the outside so it survives container upgrades or re-deployments. But this is entirely optional:

```yaml
services:
  forgejo-runner:
    image: alex3305/forgejo-runner-dind:latest
    privileged: true
    hostname: my-forgejo-runner
    network:
      internal:
    volumes:
      ~/forgejo-runner:/config
      toolcache:/home/rootless/.cache/toolcache

volumes:
  toolcache:
    name: my-forgejo-runner-hosted-toolcache
```

## Development

Building the container image is done with BuildKit and Bake:

```bash
docker buildx bake
```

The output can optionally be saved to your local Docker with the `--load` flag. 
After building testing can be done by starting the created container image:

```bash
# Docker in Docker variant
docker run --rm -it --privileged forgejo-runner-dind-rootless:latest

# Podman variant
docker run --rm -it --privileged forgejo-runner-podman-rootless:latest
```

### Cross platform compilation

To build this image cross platform, the necessary binfmt_misc kernel modules
are necessary. Those can easily be installed with the 
[tonistiigi/binfmt](https://github.com/tonistiigi/binfmt) container image:

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
```

This can also be tested with the same image or by running an alternative
platform (ie. arm64):

```bash
# Outputs the current supported platforms
docker run --privileged --rm tonistiigi/binfmt

# Should return the kernel version
docker run --rm --platform linux/arm64 alpine uname -a
```

It can also be necessary to re-create the Buildkit builder for cross-compilation
to work. This is also fairly trivial:

```bash
# Install the required kernel modules
docker run --privileged --rm tonistiigi/binfmt --install all

# Delete the current builder
docker buildx rm builder

# Re-create a new builder
docker buildx create --name builder --driver docker-container --use
```

### Release

Releases are also done with Docker Bake, but with the release profile.

```bash
docker buildx bake release
```

When a release is made the images are tagged semantically. The tags include
the following context:

* the SemVer, SemVer Minor and SemVer Major of Forgejo Runner;
* (optional) container runtime;
* (optional) SemVer, SemVer Minor and SemVer Major of the container runtime.

A few (fictional) examples:

* `10`, SemVer Major
* `10.2`, SemVer Minor
* `10.2-dind-5`, SemVer Minor, container runtime with SemVer Major
* `10-dind-5.9.1`, SemVer Major, container runtime with SemVer
* `10.2-podman-5.9.1`, SemVer Minor, container runtime with SemVer
* `10.2.0-podman-5.9.1`, SemVer, container runtime with SemVer

### Running a minimal container

For testing it can be useful to run a minimal container.

```bash
docker run -it --rm --privileged --name forgejo-runner-2 \
      --network forgejo-overlay \
      -v /opt/appdata/forgejo/runner2:/config \
      -e CONFIG_FILE=/config/config.yaml \
      alex3305/forgejo-runner-dind:latest
```

Where I have copied my primary runner configuration to test with. It is required to stop the primary Forgejo runner when doing so.

> [!TIP]
> Bash is available and can be used as an entrypoint

### Testing with a Forgejo instance

As an alternative you can test easily with your existing Forgejo instance:

```bash
docker run --rm -it --privileged --name forgejo-runner \
           -v ./.forgejo/config:/config \
           -e CONFIG_FILE=/config/config.yaml \
           -e FORGEJO_INSTANCE_URL="https://forgejo.example.com" \
           -e FORGEJO_REGISTRATION_TOKEN="<INSERT TOKEN HERE>" \
           -e FORGEJO_RUNNER_NAME="local-test-instance" \
           forgejo-runner-dind-rootless
```

> [!NOTE]
> This example assumes that you have build the images locally

### Logging

It is advised to use trace or debug logging set in the configuration file for debugging.

```yaml
log:
  # The level of logging, can be trace, debug, info, warn, error, fatal
  level: trace
  job_level: trace
```

## License

This repository is licensed under the [MIT License](LICENSE.md) unless otherwise stated.

Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc.

The Forgejo branding is licensed under the [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/) license. 

Gitea is a trademark or registered trademark of Gitea Ltd. The Gitea logo is licensed under the [MIT License](https://github.com/go-gitea/gitea/blob/main/LICENSE). 
