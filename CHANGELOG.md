# Changelog

## [0.2.0](https://github.com/AlexAsAService/Pulper/compare/v0.1.2...v0.2.0) (2026-05-10)


### Features

* modularize smoke test workflow into a reusable action ([#16](https://github.com/AlexAsAService/Pulper/issues/16)) ([6a25b8a](https://github.com/AlexAsAService/Pulper/commit/6a25b8ab44e99b60e7c3be758bbef82660edd03c))

## [0.1.2](https://github.com/AlexAsAService/Pulper/compare/v0.1.1...v0.1.2) (2026-05-09)


### Bug Fixes

* find something to change ([#13](https://github.com/AlexAsAService/Pulper/issues/13)) ([d9e534d](https://github.com/AlexAsAService/Pulper/commit/d9e534d624c1485bd21d13657d4ea1ca840c14f0))

## [0.1.1](https://github.com/AlexAsAService/Pulper/compare/v0.1.0...v0.1.1) (2026-05-09)


### Bug Fixes

* use short git sha for docker image tags and update bake registry configuration ([b57203f](https://github.com/AlexAsAService/Pulper/commit/b57203f1ad829b3f79afe640a009541831cc8989))
* use short git sha for docker image tags and update bake registry configuration ([1d6821c](https://github.com/AlexAsAService/Pulper/commit/1d6821cb5a6c5461063c3e7886f77fc8d53b8fa2))
* use short git sha for docker image tags and update bake registry… ([7fdae8a](https://github.com/AlexAsAService/Pulper/commit/7fdae8affc5d7ce7740277f51d0c016f583077bc))
* use short git sha for docker image tags and update bake registry… ([799b78a](https://github.com/AlexAsAService/Pulper/commit/799b78a78bcabca2cc8892065d1522fa73d33f98))

## 0.1.0 (2026-05-08)


### Features

* add assorted file format fixtures for testing and update smoke test script ([23c0c95](https://github.com/AlexAsAService/Pulper/commit/23c0c9510c93f83eb46f27a056e21afff2ba640f))
* add composite action to normalize REPO_OWNER to lowercase in CI workflow ([ca672ed](https://github.com/AlexAsAService/Pulper/commit/ca672edb5c590a4fed973fa044854139c3b559e0))
* add modular composite actions and refactor CI to use them ([86c59ae](https://github.com/AlexAsAService/Pulper/commit/86c59ae888fd93136b7fdf15d93ee676bb151978))
* add test fixtures and implement shim stage for auto-uid mapping ([2bb6e4d](https://github.com/AlexAsAService/Pulper/commit/2bb6e4d956267bbf6b5ef02397745e8da786568b))
* **classifier:** replace bash entrypoint with Go orchestrator and transpiler engine ([1880806](https://github.com/AlexAsAService/Pulper/commit/18808064b3e83acd92f16682b8ad6d19380fa7e7))
* implement automated release management and update CI to support tag-based image promotion ([c1fec28](https://github.com/AlexAsAService/Pulper/commit/c1fec2886820436a31e10aa587a671377323c013))
* implement file transpiler framework with LibreOffice and FFmpeg support ([ff01b14](https://github.com/AlexAsAService/Pulper/commit/ff01b146ea48825bd6790eff94d68b1edb874a15))
* implement shim stage with entrypoint script for dynamic UID/GID volume permission mapping ([20dc72e](https://github.com/AlexAsAService/Pulper/commit/20dc72e70cd26b1901e6cd597e778bf48e33bf80))
* implement universal document conversion with auto-transpilation ([7d95490](https://github.com/AlexAsAService/Pulper/commit/7d9549051f738cc9dc06e042fbb9857d3d38802e))
* include registry and repository owner in build arguments within CI workflow ([5d4ef52](https://github.com/AlexAsAService/Pulper/commit/5d4ef52117757edd679c45a7b6240455c929ab0e))
* initialize project structure with Docker, CI/CD workflows, and automation scripts ([652fcd4](https://github.com/AlexAsAService/Pulper/commit/652fcd4ace139f8ff636a8e1757cf67943225542))
* refactor Docker targets to support shimmed/unshimmed variants and integrate Go binary classifier ([0693e96](https://github.com/AlexAsAService/Pulper/commit/0693e96b3fc245d4dbc5b673188cc8886d023a5c))
* update entrypoint script for better logic flow ([cac22a5](https://github.com/AlexAsAService/Pulper/commit/cac22a5492e460870f6d2c19a041f5ff12f245c4))


### Bug Fixes

* add target input to smoke-test action for build customization ([abc51fd](https://github.com/AlexAsAService/Pulper/commit/abc51fd1b97d45d98db430c4b7d8f1e27d1e68f4))
* configure global LibreOffice user profile path in Dockerfile and remove redundant runtime environment flag ([fd29ba5](https://github.com/AlexAsAService/Pulper/commit/fd29ba5d51ec4d5e0b46fcd53ae219259d4fc8d4))
* correct image registry path variable interpolation and add diagnostic logging ([0531ce0](https://github.com/AlexAsAService/Pulper/commit/0531ce0609fd140fdefa70edf53ddab7f00a7855))
* dynamically detect UID and GID from /output directory in entrypoint script ([e38dc2a](https://github.com/AlexAsAService/Pulper/commit/e38dc2adac43ffb9fc123172cac0fbbeb2a0bd31))
* export DOCKER_OPTS variable in CI workflow to ensure availability in subsequent commands ([c1b612c](https://github.com/AlexAsAService/Pulper/commit/c1b612c9d513261450755a77078b8eab87173875))
* isolate LibreOffice user profile and update .gitignore path for classifier binary ([65446e0](https://github.com/AlexAsAService/Pulper/commit/65446e0ccc7726567c45e1340b2de88ad4846e0f))
