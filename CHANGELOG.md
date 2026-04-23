### What's changed in v0.10.1

* chore(makefile): add generate-configuration target and fix shorthand (by @patrickleet)

  Wires hops validate generate-configuration as a prerequisite of
  validate:all / validate / validate:% so configuration.yaml is
  regenerated from upbound.yaml before each validation run.

  Also switches the render/validate shorthand aliases from
  `validate: validate\:all` (which fails "No rule to make target
  `validate\:all'") to the sub-make form `$(MAKE) 'validate:all'`.

  Implements [[tasks/update-xrd-makefiles-generate-config]]

* fix: only specify major version in upbound file (by @patrickleet)


See full diff: [v0.10.0...v0.10.1](https://github.com/hops-ops/aws-pod-identity/compare/v0.10.0...v0.10.1)
