# JWTSecurityLab

JWTSecurityLab is a web application written in pure Swift. The goal is to provide educational backend for learning vulnerabilities in JWT (JSON Web Tokens).
JSON Web tokens is an industry standard specified by RFC7519 (https://tools.ietf.org/html/rfc7519).
You can play with tokens at https://jwt.io/

JWTSecurityLab consists of a set of lab lessons that will help you understand vulnerabilities in JWT.

This app uses:
1. Modified version of https://github.com/httpswift/swifter
2. https://github.com/krzyzanowskim/CryptoSwift
3. Modified version of https://github.com/kylef/JSONWebToken.swift
4. https://github.com/twbs/bootstrap


## Build docker image
```
docker build -t jwtlab:1.0 .
```
On raspberry:
```
docker build -t jwtlab:1.0 -f Dockerfile.rpi .
```

## Start Container
```
docker run -d --restart always -p 8083:5903 jwtlab:1.0
```
```
docker run --rm -p 8083:5903 jwtlab:1.4
```
