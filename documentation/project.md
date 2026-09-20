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

At the core of the application is an AI agent (not yet implemented).
This agent will help users break down tasks into smaller, bite-sized tasks to reduce mental overload and anxiety.

The long-term primary task workflow will be a recommendation list. A task will be eligible when it:

- Is `scheduled` or `in_progress`.
- Has no unmet dependencies.
- Is a leaf task (no children).

Recommendations will be ranked using criteria that may include:

- The user's available time, energy, and motivation.
- Time of day.
- Task due date, priority, and completion percentage.
- Patterns learned by the AI agent.

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
- We have implemented the tables `goals`, `tasks`, `tags`, `time_entries` and `task_notes` — the basic schema is complete.
- `task_notes` CRUD is shipped
  - Nested under tasks: `/api/tasks/:task_id/notes`.
  - A task may hold any number of notes. Task reads carry `notes_count` only; the notes
    themselves are always fetched from the nested endpoint.
- `time_entries` CRUD is shipped
  - Nested under tasks: `/api/tasks/:task_id/time_entries`.
  - A time entry with a null `ended_at` is the running timer.
  - Task-status side effects and the entries-vs-subtasks reverse guard are follow-ups.

## Thoughts

2026/05/29 - Option for users to make goals public / shareable. Not right now, better to have the personal aspect working first.

## Notes to myself

- We gotta keep in mind in which layer you are. That defines what you have access and how you need to do things.
