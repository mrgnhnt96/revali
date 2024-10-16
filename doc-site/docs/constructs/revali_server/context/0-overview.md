---
title: Overview
---

# Context

Each Lifecycle Component has a context object that is passed to it. The context object contains information about the current request, response, metadata, reflections, and more. The context object is passed to each Lifecycle Component in the order they are registered. _Most_ Lifecycle Components can modify the context object.

Each context vary depending on the Lifecycle Component. For example, the [`Middleware`](../lifecycle-components/middleware) Lifecycle Component can modify the `Request` object, while the [`Guard`](../lifecycle-components/guards) component can only read from the `Request` object.
