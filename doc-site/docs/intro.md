---
sidebar_position: 1
slug: /
---

# Revali

A Dart Code Generating Framework for API Development

Revali is a powerful code generator designed for the Dart language. It leverages annotations on your classes, methods, and method parameters to create an API. This allows you to focus on writing clean, maintainable code while Revali handles the boilerplate.

Revali employs the use of file naming conventions to determine where to look for your annotations, so naming files with the appropriate endings will be important.

**Note: this guide refers to how `revali_router` and `revali_server` work together, but the `revali` package allows you to build your own constructs as well**

---

To get started, you’ll need to install the following packages:

## Dependency

-   **revali_router**: Holds the Router class and annotations that remain in your code during compilation.

## Dev Dependencies

-   **revali**: Provides the abstracted functionalities for code generation.
-   **revali_server**: Serves as the delegate during code generation to produce your actual server.

Let’s dive into setting up your environment and start using Revali.
