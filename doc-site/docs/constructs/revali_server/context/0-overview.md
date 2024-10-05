---
title: Overview
---

# Context

Each lifecycle component has a context object that is passed to it. The context object contains information about the current request, response, metadata, reflections, and more. The context object is passed to each lifecycle component in the order they are registered. _Most_ lifecycle components can modify the context object.

Each context vary depending on the lifecycle component. For example, the [`Middleware`](../lifecycle-components/middleware) lifecycle component can modify the `Request` object, while the [`Guard`](../lifecycle-components/guards) component can only read from the `Request` object.
