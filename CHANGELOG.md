# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0]() (2026-01-24)

### ⚠ BREAKING CHANGES

* Switch from Bitnami chart to pascaliske/keycloak chart with updated configuration structure.
* AWS ALB ingress now managed via separate `kubernetes_ingress_v1` resource.

## [1.1.0]() (2025-10-12)

### ⚠ BREAKING CHANGES

* Update Helm provider version constraint to v3.

## [1.0.0]() (2025-06-17)

### BREAKING CHANGES

* Changed module name to `helm-keycloak` and flatten it to aws root folder for Terraform Registry discovery compatibility.

## [0.3.1]() (2025-03-30)

### Features

* Init module with all the code
