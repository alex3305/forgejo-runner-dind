group "default" {
  targets = ["forgejo-runner-dind-rootless"]
}

group "release" {
  targets = ["forgejo-runner-dind-rootless-release"]
}

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
  output = [{type = "cacheonly"}]
}

target "dind-rootless" {
  dockerfile = "dockerfiles/dind-rootless.Dockerfile"
  contexts = {
    base = "target:base"
  }
  output = [{type = "cacheonly"}]
}

target "forgejo-runner-dind-rootless" {
  dockerfile = "forgejo-runner-dind-rootless.Dockerfile"
  contexts = {
    base                = "target:base"
    dind-rootless       = "target:dind-rootless"
    forgejo-act-runner  = "target:forgejo-act-runner"
    s6-overlay          = "target:s6-overlay"
  }
  output = [{type = "cacheonly"}]
}

target "forgejo-runner-dind-rootless-release" {
  inherits = [
    "docker-metadata-action",
    "forgejo-runner-dind-rootless"
  ]
  platforms = ["linux/amd64", "linux/arm64"]
}
