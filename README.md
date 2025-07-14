<h3 align="center">
  <img src="assets/forgejo-animated.png" alt="Forgejo" width="100">
  <br/><br/>
  Forgejo runner ❤️ <i>dind</i>
</h3>

<h4 align="center">
  Container image that combines Forgejo Runner 🏃 with <i>Docker-in-Docker</i> 🐳.
</h4>

## Usage

### Docker Compose

```yaml
services:
  forgejo:
    image: codeberg.org/forgejo/forgejo:latest
    network:
      internal:

  forgejo-runner:
    image: alex3305/forgejo-runner-dind:latest
    privileged: true
    network:
      internal:
    volumes:
      - /opt/forgejo/runner:/config
    environment:
      CONFIG_FILE: /config/config.yaml
      FORGEJO_INSTANCE_URL: http://forgejo:3000
      FORGEJO_RUNNER_NAME: my-first-forgejo-runner
      FORGEJO_REGISTRATION_TOKEN: JLcy4PhU8wMBmt2mpu5BmW1OqDVlojtPzmQl9mdC

networks:
  internal:
    name: forgejo
```

> [!NOTE]
> Privileged mode is required for Docker in Docker to function properly. This is explained in [docker-library/docker#151](https://github.com/docker-library/docker/issues/151#issuecomment-483185972) and [docker-library/docker#281](https://github.com/docker-library/docker/issues/281#issuecomment-744766015). However this is still a security issue thats need to treated appropriately. 

### Environment variables

| Variable                     | Required |               Default               | Description |
| ---------------------------- | :------: | :---------------------------------: | ----------- |
| `FORGEJO_INSTANCE_URL`       |   ✅*    |                                     | URL of the Forgejo instance. |
| `FORGEJO_REGISTRATION_TOKEN` |   ✅*    |                                     | Forgejo Registration token. |
| `FORGEJO_RUNNER_NAME`        |    ✅    |             _hostname_              | Name of the Forgejo runner. |
| `CONFIG_FILE`                |    ❌    |                                     | The optional config file that is used for this runner. Must be a path that is mounted in the container. |
| `DOCKER_HOST`                |    ❌    | `unix:///run/user/1000/docker.sock` | The Docker socket that Forgejo Runner connects to. |
| `DOCKER_LOG_LEVEL`           |    ❌    |               `info`                | The Docker Daemon log level |
| `FORGEJO_RUNNER_LABELS`      |    ❌    |                                     | Optional Forgejo runner labels |
| `EXTRA_ARGS`                 |    ❌    |                                     | Optional additional arguments |

> [!IMPORTANT]
> The variables marked with an **&ast;** are required until the Forgejo Runner is successfully registered.

#### Forgejo Instance URL

This is the instance URL of Forgejo that must be reachable by the runner.

#### Forgejo Registration Token

The registration token is used to register Forgejo Runner to Forgejo. This works as an authentication and authorization token. This token can be found under `/admin/actions/runners` on your Forgejo instance.

> [!NOTE]
> After registration, the Forgejo Instance URL and Registration Token will be stored in a `/config/.runner` file. After this file is created, the provided environment variables will not be used.

### Configuration file

It is also possible to generate a Forgejo Runner configuration file. This provides far more customization and options than just using the runner.

```bash
docker run -t --rm \
        --name forgejo-config-generator \
        --entrypoint forgejo-runner \
        alex3305/forgejo-runner-dind:latest \
        generate-config
```

Which will generate the latest template configuration to standard out. This can also be output to a file for later use.

```bash
mkdir -p /opt/forgejo/runner/
docker run -t --rm \
        --name forgejo-config-generator \
        --entrypoint forgejo-runner \
        alex3305/forgejo-runner-dind:latest \
        generate-config > /opt/forgejo/runner/config.yaml
```

#### Required variables

Within the configuration file it is required for the following options to be set:

```yaml
container:
  # Whether to use privileged mode or not when launching task containers (privileged mode is required for Docker-in-Docker).
  privileged: true
  # overrides the docker client host with the specified one.
  # If "-" or "", an available docker host will automatically be found.
  # If "automount", an available docker host will automatically be found and mounted in the job container (e.g. /var/run/docker.sock).
  # Otherwise the specified docker host will be used and an error will be returned if it doesn't work.
  docker_host: "automount"
```

Failing to do so may lead to unexpected results. For instance in jobs not starting or unable to access the Docker daemon within a job.

## Development

Building the container image is done with BuildKit:

```bash
docker buildx build . -t forgejo-runner-dind
```

After which testing can be done by starting the created container image:

```bash
docker run --rm -it --privileged forgejo-runner-dind
```

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
