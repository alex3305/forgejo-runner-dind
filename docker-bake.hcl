group "default" {
  targets = ["forgejo-runner-dind-rootless"]
}

variable "TAG" {
  default = "latest"
}

# variable "FORGEJO_ACT_RUNNER_VERSION" {}
# variable "CONTAINER_TOOL" {}
# variable "CONTAINER_TOOL_VERSION" {}

target "base" {
  dockerfile = "dockerfiles/base.Dockerfile"
  output = [{ type = "cacheonly" }]
}

target "s6-overlay" {
  dockerfile = "dockerfiles/s6-overlay.Dockerfile"
  contexts = {
    base = "target:base"
  }
  output = [{ type = "cacheonly" }]
}

target "forgejo-act-runner" {
  dockerfile = "dockerfiles/forgejo-act-runner.Dockerfile"
  contexts = {
    base = "target:base"
  }
  output = [{ type = "cacheonly" }]
  # platforms = ["linux/amd64", "linux/arm64"]
}

target "dind-rootless" {
  dockerfile = "dockerfiles/dind-rootless.Dockerfile"
  contexts = {
    base = "target:base"
  }
  output = [{ type = "cacheonly" }]
}

target "forgejo-runner-dind-rootless" {
  dockerfile = "forgejo-runner-dind-rootless.Dockerfile"
  contexts = {
    base                = "target:base",
    dind-rootless       = "target:dind-rootless",
    forgejo-act-runner  = "target:forgejo-act-runner",
    s6-overlay          = "target:s6-overlay",
  }
  tags = [
    "alex3305/forgejo-runner-dind:${TAG}",
    "ghcr.io/alex3305/forgejo-runner-dind:${TAG}"
  ]
}
