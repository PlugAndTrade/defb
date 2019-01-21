# Defb
[![Build Status](https://travis-ci.org/PlugAndTrade/defb.svg?branch=master)](https://travis-ci.org/PlugAndTrade/defb)
[![Docker build](https://img.shields.io/docker/build/plugandtrade/defb.svg)](https://hub.docker.com/r/plugandtrade/defb)

A smart default-backend for [`ingress-nginx`](https://kubernetes.github.io/ingress-nginx/)

## Example

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: echoserver
  namespace: default
  labels:
    app.kubernetes.io/part-of: defb
    app.kubernetes.io/custom-errors: defb
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
