```mermaid
%%{init: {'theme': 'default'}}%%
graph TD
  A[Mobile App / Flutter]
  B[Backend / FastAPI]
  C[Cloud Run]
  D[Google Vision API]
  E[Artifact Registry]
  F[Terraform / Infra]
  G[Workload Identity Federation / WIF]
  H[GitHub Actions / CICD]

  A -->| /v1/ocr & /v1/assess | B
  B --> C
  C --> D
  C --> E
  F -->| provisions | C
  F --> G
  H -->| deploys/tests | B
  H -->| applies | F
  ```
