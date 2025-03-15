<h3 align="center">
  <img src="assets/forgejo-animated.png" alt="Forgejo" width="100">
  <br/><br/>
  Forgejo runner ❤️ <i>dind</i>
</h3>

<h4 align="center">
  Container image that combines Forgejo Runner 🏃 with <i><abbr="Docker-in-Docker">dind</a></i> 🐳.
</h4>

<p align="center">
  <br/>
  <img src="https://git.1d.lol/containers/forgejo-runner-dind/actions/workflows/build.yaml/badge.svg" alt="Build" title="Build status">
  <img src="https://git.1d.lol/containers/forgejo-runner-dind/actions/workflows/lint.yaml/badge.svg" alt="Lint" title="Lint status">
  <img src="https://git.1d.lol/containers/forgejo-runner-dind/actions/workflows/sync-labels.yaml/badge.svg" alt="Sync Labels" title="Label Sync result">
</p>

## Usage

### Docker Compose

```yaml
services:
  forgejo-runner:
    image: git.1d.lol/containers/forgejo-dind-runner:latest
    privileged: true
    environment:
      DOCKER_HOST: unix:///var/run/user/1000/docker.sock
      FORGEJO_INSTANCE_URL: http://git:3000
      FORGEJO_REGISTRATION_TOKEN: rF68npwbO74nU4zKmWGWDmq3xWKPEUpe
```

### Environment variables

| Variable                     | Required |  Default   | Description                                                                                             |
| ---------------------------- | :------: | :--------: | ------------------------------------------------------------------------------------------------------- |
| `FORGEJO_INSTANCE_URL`       |   ✅*    |            | URL of the Forgejo instance. This is a required variable, unless the runner is already registered.      |
| `FORGEJO_REGISTRATION_TOKEN` |   ✅*    |            | Forgejo Registration token _(see below)_                                                                |
| `FORGEJO_RUNNER_NAME`        |    ✅    | _hostname_ | Name of the Forgejo runner. This defaults to the hostname of the container.                             |
| `CONFIG_FILE`                |    ❌    |            | The optional config file that is used for this runner. Must be a path that is mounted in the container. |
| `MAX_REG_ATTEMPTS`           |    ❌    |     10     | Maximum registration attempts                                                                           |
| `FORGEJO_RUNNER_LABELS`      |    ❌    |            | Optional Forgejo runner labels                                                                          |
| `EXTRA_ARGS`                 |    ❌    |            | Optional additional arguments                                                                           |

#### Forgejo Instance URL

_TODO_

#### Forgejo Registration Token

_TODO_

## Development

_TODO_

## License

This repository is licensed under the [MIT License](LICENSE.md) unless otherwise stated.

Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc.

The Forgejo name, branding and logo is licensed under the [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/) license. 

The Gitea name, branding and logo is licensed under the [MIT License](https://github.com/go-gitea/gitea/blob/main/LICENSE). This also includes some part of the code that exists in this repository.
