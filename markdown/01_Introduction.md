# Introduction

This is an introduction snippet. It will be the first visible section after the front matter (cover page and ToC).

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

Here is an example of a mermaid ERD

```mermaid
erDiagram
    Object1 ||--o{ Object2 : ConnectionType
    Object3 ||--o{ Object2 : ConnectionType
    Object1 {
        id Id
        string Name
    }
    Object2 {
        id Id
        string Name
        id Object1Id
        id Object3Id
    }
    Object3 {
        id Id
        string Name
    }
```
