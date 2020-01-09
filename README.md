# Defb
[![Build Status](https://travis-ci.org/PlugAndTrade/defb.svg?branch=master)](https://travis-ci.org/PlugAndTrade/defb)
[![Docker build](https://img.shields.io/docker/build/plugandtrade/defb.svg)](https://hub.docker.com/r/plugandtrade/defb)

A smart default-backend for [`ingress-nginx`](https://kubernetes.github.io/ingress-nginx/)

# Overview

The default-backed is used when `ingress-nginx` is not able to route the request to an upstream kuberentes service,
coupled with the option `customm-http-errors` provides the ability for `ingress-nginx` to pass several HTTP headers down to `defb` in case of error.

`defb` uses this information to provide custom error pages, per service, per content-type, instead of one global. In case a service does not have an error configmap defined the global default will be used:

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: echoserver-error-pages
  namespace: default
  labels:
    app.kubernetes.io/part-of: defb
    app.kubernetes.io/custom-errors: defb
    default-http-backend/alternate-name: echoserver-svc
data:
  5xx.html: |
    <html>
    <body>
        <p>generic html error</p>
    </body>
    </html>
  500.json: |
    {
      "message": "internal server error"
    }
  503.json: |
    {
      "message": "service unavailable"
    }
  5xx.json: |
    {
      "message": "generic json error"
    }
```

This configmap defines a custom error template for a `svc` named `echoserver-svc` in the `default` namespace.

The following rules apply:

* ANY `500` error where the original request had a `Accept` header `text/html` will return the `5xx` `HTML` error.
* `500` error where the original request had a `Accept` header `application/json` will return `{ "message": "internal server error" }`
* `503` error where the original request had a `Accept` header `application/json` will return `{ "message": "service unavailable" }`
* ANY  other `500` error where the original request had a `Accept` header `application/json` will return `{ "message": "generic json error" }`


For configuring `ingress-nginx` to use `defb` as the default-http-backend see: [custom errors](https://github.com/kubernetes/ingress-nginx/tree/master/docs/examples/customization/custom-errors)

## Custom default pages

When there's no error page entry for a service, `defb` will fallback to `/etc/defb/pages` (see `/pages` in this repository). These files can be replaced with your own if you'd like a different fallback pages.

## Metrics
Prometheus metrics are exposed on port 3000 `/metrics`

## Developing

### Prerequisites
* [minikube](https://kubernetes.io/docs/setup/minikube/)
* [Erlang & Elixir](https://elixir-lang.org/install.html)

Minikube or other K8s environment needed.

* Intall dependencies

```
mix deps.get
```

* Compile

```
mix compile
```

* Running

`iex -S mix`
