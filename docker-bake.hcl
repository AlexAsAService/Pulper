# docker-bake.hcl
#
# High-performance multi-target build configuration.
# This file is used by 'docker buildx bake' to build all 4 targets
# in a single optimized pass, sharing layers efficiently.

variable "TAG" {
  default = "latest"
}

variable "REGISTRY" {
  default = "ghcr.io/alexasaservice"
}

# Common configuration shared by all targets
target "_common" {
  context = "."
  dockerfile = "Dockerfile"
}

# --- FULL VARIANTS (Pulper) ---

target "pulper" {
  inherits = ["_common"]
  target   = "full-shim"
  tags     = ["${REGISTRY}/pulper:${TAG}"]
}

target "pulper-no-shim" {
  inherits = ["_common"]
  target   = "full-no-shim"
  tags     = ["${REGISTRY}/pulper:${TAG}-no-shim"]
}

# --- LITE VARIANTS (Pulper-Lite) ---

target "pulper-lite" {
  inherits = ["_common"]
  target   = "minimal-shim"
  tags     = ["${REGISTRY}/pulper-lite:${TAG}"]
}

target "pulper-lite-no-shim" {
  inherits = ["_common"]
  target   = "minimal-no-shim"
  tags     = ["${REGISTRY}/pulper-lite:${TAG}-no-shim"]
}

# Default group to build all targets
group "default" {
  targets = ["pulper", "pulper-no-shim", "pulper-lite", "pulper-lite-no-shim"]
}
