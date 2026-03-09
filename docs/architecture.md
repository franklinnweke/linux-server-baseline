# Architecture

```mermaid
flowchart TD
  U[User Browser] --> D[DNS A Record]
  D --> N[Nginx TLS Reverse Proxy]
  N --> A[App Container]
  A --> V[Persistent Volume]
```
