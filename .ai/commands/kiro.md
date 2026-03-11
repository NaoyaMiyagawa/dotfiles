---
description: "spec-driven development"
---

Spec-driven development using AI agent.

## What is spec-driven development

Spec-driven development is a development methodology consisting of the following 5 phases.

### 1. Preparation Phase

- The user communicates the overview of the task they want AI agent tool to execute.
  - if no description is provided, please fetch PR description using GitHub CLI and analyse based on it
- In this phase, execute `mkdir -p ./.cckiro/specs`
- Within `./cckiro/specs`, create a directory with an appropriate spec name based on the task overview
    - If it's not on `main` `develop` branch, try to use branch name unless there is a directory with same name already
    - As fallback naming principle, for example, if the task is "create an article component", create a directory named `./cckiro/specs/create-article-component`
- When creating the following files, create them within this directory

### 2. Requirements Phase

- Creates a "requirements file" `1_requirements.md` based on the task overview communicated by the user, describing what the task should accomplish
- Presents the "requirements file" to the user and asks if there are any issues
- The user reviews the "requirements file" and provides feedback to AI agent if there are problems
- Repeats revisions to the "requirements file" until the user confirms there are no issues

### 3. Design Phase

- Creates a "design file" `2_design.md` describing the design that fulfills the requirements listed in the "requirements file"
- Presents the "design file" to the user and asks if there are any issues
- The user reviews the "design file" and provides feedback to AI agent if there are problems
- Repeats revisions to the "requirements file" until the user confirms there are no issues

### 4. Implementation Planning Phase

- Creates an "implementation plan file" `3_todo.md` with clear todo list in markdown format for implementing the design described in the "design file"
- This file will be also used to visually track the progress by the user
- Presents the "implementation plan file" to the user and asks if there are any issues
- The user reviews the "implementation plan file" and provides feedback to AI agent if there are problems
- Repeats revisions to the "requirements file" until the user confirms there are no issues

### 5. Implementation Phase

- Begins implementation based on the "implementation plan file"
- While implementing, please follow the content described in the "requirements file" and "design file"
- Also, please mark todo items ticked every time you complete one user can see progress in live

## General Rules
- Please write in simple and clear words. Don't bloat the docs up.
