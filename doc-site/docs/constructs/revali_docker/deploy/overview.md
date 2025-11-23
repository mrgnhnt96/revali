---
title: Overview
sidebar_position: 0
description: Deploy your Revali Docker container to production
---

# Deployment Overview

Once you've generated a Dockerfile with Revali Docker, you're ready to deploy your application to production. This guide covers deployment strategies, platform choices, and best practices for running Revali applications in containers.

## Deployment Process

Deploying a Revali Docker application typically follows these steps:

1. **Generate the Dockerfile** - Run `revali build` to create your Dockerfile
2. **Build the Docker Image** - Compile your application into a container image
3. **Test Locally** - Verify the container works on your machine
4. **Push to Registry** - Upload your image to a container registry
5. **Deploy to Platform** - Deploy the image to your hosting provider
6. **Configure & Monitor** - Set up environment variables, scaling, and monitoring

---

## Choosing a Deployment Platform

Different platforms offer different trade-offs between simplicity, control, and cost. Here's a comparison:

| Platform                                                                         | Best For                         | Ease of Use | Pricing       | Free Tier |
| -------------------------------------------------------------------------------- | -------------------------------- | ----------- | ------------- | --------- |
| [Fly.io](/constructs/revali_docker/deploy/fly.io)                                | Global deployment, low latency   | ⭐⭐⭐⭐⭐  | Pay-as-you-go | Yes       |
| [Railway](https://railway.app/)                                                  | Quick deployment, hobby projects | ⭐⭐⭐⭐⭐  | Usage-based   | Yes       |
| [Render](https://render.com/)                                                    | Simple setup, managed services   | ⭐⭐⭐⭐    | Fixed pricing | Yes       |
| [DigitalOcean App Platform](https://www.digitalocean.com/products/app-platform/) | Balanced control & simplicity    | ⭐⭐⭐⭐    | Fixed pricing | No        |
| [Heroku](https://www.heroku.com/)                                                | Beginner-friendly, add-ons       | ⭐⭐⭐⭐    | Dyno-based    | No        |

---

## What's Next?

- **[Fly.io Deployment Guide](/constructs/revali_docker/deploy/fly.io)** - Detailed Fly.io setup
- **[Revali Docker Overview](/constructs/revali_docker/overview)** - Learn more about Docker generation

Ready to deploy? Choose a platform above and follow their quick start guide!
