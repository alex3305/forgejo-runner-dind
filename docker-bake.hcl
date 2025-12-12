# Docker Bake configuration

# Constants that are managed by Renovate
# renovate: datasource=github-releases depName=moby packageName=moby/moby
DOCKER_VERSION = "28.5.2"
# renovate: datasource=gitea-releases depName=forgejo-runner packageName=forgejo/runner registryUrl=https://code.forgejo.org/
FORGEJO_RUNNER_VERSION = "12.1.2"
# renovate: datasource=github-releases depName=podman packageName=containers/podman
PODMAN_VERSION = "5.7.0"
# renovate: datasource=github-releases depName=s6-overlay packageName=just-containers/s6-overlay
S6_OVERLAY_VERSION = "3.2.1.0"


# Variables
variable "FORGEJO_RUNNER_VERSION" {
  validation {
    condition = FORGEJO_RUNNER_VERSION != ""
    error_message = "Forgejo Runner version must not be empty"
  }

  validation {
    condition = FORGEJO_RUNNER_VERSION == regex("\\d.*\\.\\d.*\\.\\d.*", FORGEJO_RUNNER_VERSION)
    error_message = "Forgejo Runner version must be in SemVer format"
  }
}

variable "FORGEJO_RUNNER_VERSION_MAJOR" {
  default = "${regex("(\\d.*)\\.\\d.*\\.\\d.*", FORGEJO_RUNNER_VERSION)[0]}"
}

variable "FORGEJO_RUNNER_VERSION_MINOR" {
  default = "${regex("(\\d.*\\.\\d.*)\\.\\d.*", FORGEJO_RUNNER_VERSION)[0]}"
}

variable "DOCKER_VERSION" {
  validation {
    condition = DOCKER_VERSION != ""
    error_message = "Docker version must not be empty"
  }

  validation {
    condition = DOCKER_VERSION == regex("\\d.*\\.\\d.*\\.\\d.*", DOCKER_VERSION)
    error_message = "Docker version must be in SemVer format"
  }
}

variable "DOCKER_VERSION_MAJOR" {
  default = "${regex("(\\d.*)\\.\\d.*\\.\\d.*", DOCKER_VERSION)[0]}"
}

variable "DOCKER_VERSION_MINOR" {
  default = "${regex("(\\d.*\\.\\d.*)\\.\\d.*", DOCKER_VERSION)[0]}"
}

variable "PODMAN_VERSION" {
  validation {
    condition = PODMAN_VERSION != ""
    error_message = "Podman version must not be empty"
  }

  validation {
    condition = PODMAN_VERSION == regex("\\d.*\\.\\d.*\\.\\d.*", PODMAN_VERSION)
    error_message = "Podman version must be in SemVer format"
  }
}

variable "PODMAN_VERSION_MAJOR" {
  default = "${regex("(\\d.*)\\.\\d.*\\.\\d.*", DOCKER_VERSION)[0]}"
}

variable "PODMAN_VERSION_MINOR" {
  default = "${regex("(\\d.*\\.\\d.*)\\.\\d.*", DOCKER_VERSION)[0]}"
}

variable "S6_OVERLAY_VERSION" {
  validation {
    condition = S6_OVERLAY_VERSION != ""
    error_message = "S6 Overlay version must not be empty"
  }
}


# Groups
group "default" {
  targets = ["build"]
}

group "build" {
  targets = [
    "build-forgejo-runner-dind-rootless",
    "build-forgejo-runner-podman-rootless"
  ]
}

group "release" {
  targets = [
    "release-forgejo-runner-dind-rootless",
    "release-forgejo-runner-podman-rootless"
  ]
}


# Targets
target "docker-metadata-action" {}

target "base" {
  dockerfile  = "dockerfiles/base.Dockerfile"
  output      = [ {type = "cacheonly"} ]
}

target "s6-overlay" {
  dockerfile  = "dockerfiles/s6-overlay.Dockerfile"
  contexts    = {base = "target:base"}
  args        = {S6_OVERLAY_VERSION = "${S6_OVERLAY_VERSION}"}
  output      = [ {type = "cacheonly"} ]
}

target "forgejo-act-runner" {
  dockerfile  = "dockerfiles/forgejo-act-runner.Dockerfile"
  contexts    = {base = "target:base"}
  args        = {FORGEJO_RUNNER_VERSION = "${FORGEJO_RUNNER_VERSION}"}
  output      = [ {type = "cacheonly"} ]
}

target "dind-rootless" {
  dockerfile  = "dockerfiles/dind-rootless.Dockerfile"
  contexts    = {base = "target:base"}
  args        = {DOCKER_VERSION = "${DOCKER_VERSION}"}
  output      = [ {type = "cacheonly"} ]
}

target "podman-rootless" {
  dockerfile  = "dockerfiles/podman-rootless.Dockerfile"
  contexts    = {base = "target:base"}
  args        = {PODMAN_VERSION = "${PODMAN_VERSION}"}
  output      = [ {type = "cacheonly"} ]
}

target "build-forgejo-runner-dind-rootless" {
  dockerfile  = "forgejo-runner-dind-rootless.Dockerfile"
  contexts = {
    dind-rootless       = "target:dind-rootless"
    forgejo-act-runner  = "target:forgejo-act-runner"
    s6-overlay          = "target:s6-overlay"
  }
  args = {
    FORGEJO_RUNNER_VERSION  = "${FORGEJO_RUNNER_VERSION}"
    DOCKER_VERSION          = "${DOCKER_VERSION}"
  }
  tags = [
    "forgejo-runner-dind:latest",
    "forgejo-runner-dind-rootless:latest"
  ]
}

target "release-forgejo-runner-dind-rootless" {
  name = "release-dind-${sha1(registry)}"
  inherits = [
    "docker-metadata-action",
    "build-forgejo-runner-dind-rootless"
  ]
  platforms = ["linux/amd64", "linux/arm64"]
  matrix = {
    registry = [
      "docker.io/alex3305/forgejo-runner-dind",
      "ghcr.io/alex3305/forgejo-runner-dind",
      "1d.lol/containers/forgejo-runner-dind"
    ]
  }
  tags = [
    "${registry}:latest",
    "${registry}:${FORGEJO_RUNNER_VERSION}",
    "${registry}:${FORGEJO_RUNNER_VERSION}-dind",
    "${registry}:${FORGEJO_RUNNER_VERSION}-dind-${DOCKER_VERSION}",
    "${registry}:${FORGEJO_RUNNER_VERSION}-dind-${DOCKER_VERSION_MINOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION}-dind-${DOCKER_VERSION_MAJOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}-dind",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}-dind-${DOCKER_VERSION}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}-dind-${DOCKER_VERSION_MINOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}-dind-${DOCKER_VERSION_MAJOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}-dind",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}-dind-${DOCKER_VERSION}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}-dind-${DOCKER_VERSION_MINOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}-dind-${DOCKER_VERSION_MAJOR}",
  ]
}

target "build-forgejo-runner-podman-rootless" {
  dockerfile  = "forgejo-runner-podman-rootless.Dockerfile"
  contexts = {
    podman-rootless     = "target:podman-rootless"
    forgejo-act-runner  = "target:forgejo-act-runner"
    s6-overlay          = "target:s6-overlay"
  }
  args = {
    FORGEJO_RUNNER_VERSION  = "${FORGEJO_RUNNER_VERSION}"
    PODMAN_VERSION          = "${PODMAN_VERSION}"
  }
  tags = [
    "forgejo-runner-podman:latest",
    "forgejo-runner-podman-rootless:latest",
  ]
}

target "release-forgejo-runner-podman-rootless" {
  name = "release-podman-${sha1(registry)}"
  inherits = [
    "docker-metadata-action",
    "build-forgejo-runner-podman-rootless"
  ]
  platforms = ["linux/amd64", "linux/arm64"]
  matrix = {
    registry = [
      "docker.io/alex3305/forgejo-runner-dind",
      "ghcr.io/alex3305/forgejo-runner-dind",
      "1d.lol/containers/forgejo-runner-dind"
    ]
  }
  tags = [
    "${registry}:${FORGEJO_RUNNER_VERSION}",
    "${registry}:${FORGEJO_RUNNER_VERSION}-podman",
    "${registry}:${FORGEJO_RUNNER_VERSION}-podman-${PODMAN_VERSION}",
    "${registry}:${FORGEJO_RUNNER_VERSION}-podman-${PODMAN_VERSION_MINOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION}-podman-${PODMAN_VERSION_MAJOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}-podman",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}-podman-${PODMAN_VERSION}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}-podman-${PODMAN_VERSION_MINOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MINOR}-podman-${PODMAN_VERSION_MAJOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}-podman",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}-podman-${PODMAN_VERSION}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}-podman-${PODMAN_VERSION_MINOR}",
    "${registry}:${FORGEJO_RUNNER_VERSION_MAJOR}-podman-${PODMAN_VERSION_MAJOR}",
  ]
}
