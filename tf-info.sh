#!/usr/bin/env bash
tofu show -json | jq 'def by(k): group_by(.[k]) | map({(.[0].[k]): .}) | add; .values.root_module.resources | by("mode") | map_values(by("type") | map_values(map({(.name): .}) | add))' > terraform.json
