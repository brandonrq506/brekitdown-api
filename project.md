# Sendero

## What is

Sendero is a pet project app which serves as practice to learn and experiment with technologies and pattenrs.
Despite being a pet project, it follows enterprise-grade patterns and best practices.
The reason is simple: This project is practice, and you must practice perfection, not bad habits.

## What it consists of

Sendero is a Goals app.
It has primitives like `Goals`, `Tasks`, `TimeEntries`.

At the core of the application is an AI agent.
This agent will help you break down tasks into smaller bite-size tasks to reduce mental overlaod and anxiety.
This agent will also learn user patterns, energy level and motiviation mechanisms, and will use it to recommend tasks based on muti-dimensional criteria, such as: time of the day, energy level, motivation level, task due date, priority, etc.

## What's made of

- Elixir/Phoenix api-only backend.
  - PostgreSQL.
- React + Vite frontend
  - Typescript
  - TailwindCSS
  - Tanstack Router
  - Tanstack Query + Axios

## Progress

- Project has been created.
- Auth in progress (`users` table). See `auth-discussion.md`.

## Thoughts

2026/05/29 - Option for users to make goals public / shareable. Not right now, better to have the personal aspect working first.

## Notes to myself

- We gotta keep in mind in which layer you are. That defines what you have access and how you need to do things.

## Good AI relevant discussions

- schema-design
  - /resume 91c2c5dd-fa4e-47a3-a01a-85b73eea9fc8
  - Talks about how to design the schema using the AI tool for schema design.

- task-lifecycle-policy-design
  - /resume 8c07b20a-878d-4fef-a173-1e453cb122cd
  - Talks about scopes and how to scope different features of this project.