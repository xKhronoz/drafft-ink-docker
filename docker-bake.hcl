variable "DRAFFTINK_REPO" {
  default = "https://github.com/PatWie/drafft-ink.git"
}

variable "DRAFFTINK_REF" {
  default = "main"
}

variable "DRAFFTINK_SHA" {
  default = ""
}

variable "IMAGE_VERSION" {
  default = "dev"
}

variable "SOURCE_REPOSITORY" {
  default = "https://github.com/xkhronoz/drafft-ink-docker"
}

variable "UPSTREAM_REPOSITORY" {
  default = "https://github.com/PatWie/drafft-ink"
}

variable "DOCKERHUB_NAMESPACE" {
  default = "local"
}

variable "RELEASE_TAG" {
  default = "dev"
}

group "default" {
  targets = ["server", "web", "bundled"]
}

target "_common" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  args = {
    DRAFFTINK_REPO = DRAFFTINK_REPO
    DRAFFTINK_REF = DRAFFTINK_REF
    DRAFFTINK_SHA = DRAFFTINK_SHA
    IMAGE_VERSION = IMAGE_VERSION
    SOURCE_REPOSITORY = SOURCE_REPOSITORY
    UPSTREAM_REPOSITORY = UPSTREAM_REPOSITORY
  }
}

target "server" {
  inherits = ["_common"]
  target = "server"
  tags = [
    "docker.io/${DOCKERHUB_NAMESPACE}/drafft-ink-docker:server",
    "docker.io/${DOCKERHUB_NAMESPACE}/drafft-ink-docker:server-latest",
    "docker.io/${DOCKERHUB_NAMESPACE}/drafft-ink-docker:server-${RELEASE_TAG}",
  ]
  cache-from = ["type=gha,scope=drafftink-server"]
  cache-to = ["type=gha,mode=max,scope=drafftink-server"]
}

target "web" {
  inherits = ["_common"]
  target = "web"
  tags = [
    "docker.io/${DOCKERHUB_NAMESPACE}/drafft-ink-docker:web",
    "docker.io/${DOCKERHUB_NAMESPACE}/drafft-ink-docker:web-latest",
    "docker.io/${DOCKERHUB_NAMESPACE}/drafft-ink-docker:web-${RELEASE_TAG}",
  ]
  cache-from = ["type=gha,scope=drafftink-web"]
  cache-to = ["type=gha,mode=max,scope=drafftink-web"]
}

target "bundled" {
  inherits = ["_common"]
  target = "bundled"
  tags = [
    "docker.io/${DOCKERHUB_NAMESPACE}/drafftink-docker:latest",
    "docker.io/${DOCKERHUB_NAMESPACE}/drafftink-docker:${RELEASE_TAG}",
  ]
  cache-from = ["type=gha,scope=drafftink-bundled"]
  cache-to = ["type=gha,mode=max,scope=drafftink-bundled"]
}
