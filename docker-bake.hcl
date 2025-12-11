# Docker Bake configuration

# Variables
variable "FORGEJO_ACT_RUNNER_VERSION" {
  default = "12.1.2"
}

variable "DOCKER_VERSION" {
  default = "28.5.2"
}


# Groups
group "default" {
  targets = ["build"]
}

group "build" {
  targets = [
    "build-forgejo-runner-dind-rootless"
  ]
}

group "release" {
  targets = [
    "release-forgejo-runner-dind-rootless"
  ]
}


# Targets
target "docker-metadata-action" {}

target "base" {
  dockerfile = "dockerfiles/base.Dockerfile"
  output = [{type = "cacheonly"}]
}

target "s6-overlay" {
  dockerfile = "dockerfiles/s6-overlay.Dockerfile"
  contexts = {
    base = "target:base"
  }
  output = [{type = "cacheonly"}]
}

target "forgejo-act-runner" {
  dockerfile = "dockerfiles/forgejo-act-runner.Dockerfile"
  contexts = {
    base = "target:base"
  }
  args = {
    FORGEJO_RUNNER_VERSION = "${FORGEJO_ACT_RUNNER_VERSION}"
  }
  output = [{type = "cacheonly"}]
}

target "dind-rootless" {
  dockerfile = "dockerfiles/dind-rootless.Dockerfile"
  contexts = {
    base = "target:base"
  }
  args = {
    DOCKER_VERSION = "${DOCKER_VERSION}"
  }
  output = [{type = "cacheonly"}]
}

target "build-forgejo-runner-dind-rootless" {
  dockerfile = "forgejo-runner-dind-rootless.Dockerfile"
  contexts = {
    base                = "target:base"
    dind-rootless       = "target:dind-rootless"
    forgejo-act-runner  = "target:forgejo-act-runner"
    s6-overlay          = "target:s6-overlay"
  }
  args = {
    FORGEJO_RUNNER_VERSION  = "${FORGEJO_ACT_RUNNER_VERSION}"
    DOCKER_VERSION          = "${DOCKER_VERSION}"
  }
  tags = ["forgejo-runner-dind-rootless"]
}

target "release-forgejo-runner-dind-rootless" {
  inherits = [
    "docker-metadata-action",
    "forgejo-runner-dind-rootless"
  ]
  platforms = ["linux/amd64", "linux/arm64"]
}
