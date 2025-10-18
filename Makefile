clean:
	rm -rf _output
	rm -rf .up

build:
	up project build

render: render-example

render-all: render-example

render-example:
	up composition render apis/xpodidentities/composition.yaml examples/xpodidentities/full-schema.yaml

test:
	up test run tests/*

validate: validate-composition validate-example

validate-composition:
	up composition render apis/xpodidentities/composition.yaml examples/xpodidentities/full-schema.yaml --include-full-xr --quiet | crossplane beta validate apis/xpodidentities --error-on-missing-schemas -

validate-example:
	crossplane beta validate apis/xpodidentities examples/xpodidentities

publish:
	@if [ -z "$(tag)" ]; then echo "Error: tag is not set. Usage: make publish tag=<version>"; exit 1; fi
	up project build --push --tag $(tag)

generate-definitions:
	up xrd generate examples/xpodidentities/full-schema.yaml

generate-function:
	up function generate --language=go-templating render apis/xpodidentities/composition.yaml
