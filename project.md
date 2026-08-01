# Sendero

## What is

Sendero is a pet project app which serves as practice to learn and experiment with technologies and patterns.
The main purpose of this project is to learn and practice Elixir/Phoenix, as well as improve my AI usage.
Despite being a pet project, it follows enterprise-grade patterns and best practices.
The reason is simple: This project is practice, and you must practice perfection, not bad habits.

This codebase is api-only, and the frontend is a separate project.
Anything that looks like a frontend feature here is either a mistake, or something added by generators.

## What it consists of

Sendero is a Goals app.
It has primitives like `Users`, `Goals`, `Tasks`, `Tags` and `TimeEntries`.

At the core of the application is an AI agent (Not yet implemented).
This agent will help you break down tasks into smaller bite-size tasks to reduce mental overload and anxiety.
This agent will also learn user patterns, energy level and motivation mechanisms, and will use it to recommend tasks based on multi-dimensional criteria, such as: time of the day, energy level, motivation level, task due date, priority, etc.

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
- Auth is now working, although it only uses Bearer tokens for now. Eventually we will use Cookies.
- The project will be hosted on Railway, both backend and frontend.
- We have implemented the tables `goals`, `tasks` and `tags`, we are only missing `time_entries` table to have a complete basic schema.

## Thoughts

2026/05/29 - Option for users to make goals public / shareable. Not right now, better to have the personal aspect working first.

## Notes to myself

- We gotta keep in mind in which layer you are. That defines what you have access and how you need to do things.
