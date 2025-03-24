---
title: Analysis Process
description: How Revali Client analyzes your server code
sidebar_position: 1
---

# Analysis Process

Revali Client analyzes your server code to generate the best possible client code. Using the same types depicted by the controller's endpoints and constructing all the required params, headers, body, etc.

## Best Practices

### Do's ✅

🚀: Can be used in both lifecycle methods and controller's endpoints

- Use [`LifecycleComponents`][lifecycle-components] to define middleware
- 🚀 Use [`Cookie`][cookie] to access cookies in the request
- 🚀 Use [`MutableSetCookies`][mutable-set-cookies] to set cookies in the response
- 🚀 Use [`Header`][header] to access headers in the request

### Don'ts ❌

- Don't use [`ReadOnlyCookies`][cookie] to access cookies in the request, use [`Cookie`][cookie] instead
  - Without `Cookie`, Revali Client will not know which cookie you're trying to access which will result in a cookie not being sent to the server

[lifecycle-components]: ../../revali_server/lifecycle-components/overview.md
[cookie]: ../../revali_server/core/implied_binding.md#requestresponse
[mutable-set-cookies]: ../../revali_server/core/implied_binding.md
[header]: ../../revali_server/core/implied_binding.md
