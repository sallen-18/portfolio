---
title: "Building My Cloud Portfolio"
description: "Why I'm building a portfolio site to document my cloud learning journey, and how I set it up with Astro and AWS."
date: 2026-02-05
tags: ["aws", "astro", "portfolio"]
image: "/images/portfolio-thumb.svg"
github: "https://github.com/sam/portfolio"
---

## Why a portfolio?

I wanted a place to document everything I'm learning about cloud computing. Writing things down forces me to actually understand them, and having a public record keeps me accountable.

## The setup

This site is built with [Astro](https://astro.build), a static site generator that outputs plain HTML with zero JavaScript by default. Project write-ups are written in Markdown, which makes it easy to include code snippets and architecture diagrams.

The site is hosted on **AWS S3** with **CloudFront** as a CDN, giving me hands-on experience with core AWS services.

## What's coming

I plan to write about:

- Cloud architecture patterns I'm learning
- Project walkthroughs with architecture diagrams
- Demo videos for the projects I build
- Lessons learned from certifications and hands-on labs

Each project can include architecture diagrams as images and embedded YouTube videos for demos.

## Example code block

Here's the Astro content collection schema that powers this site:

```typescript
const projects = defineCollection({
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.coerce.date(),
    tags: z.array(z.string()).default([]),
    image: z.string(),
    github: z.string(),
    youtubeId: z.string().optional(),
  }),
});
```

Stay tuned for more projects as I build things out.
