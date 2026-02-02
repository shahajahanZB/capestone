# Azure Deployment Guide (Student Account) 🔷

This guide explains how to deploy the frontend to **Azure** using GitHub Actions. It focuses on low-cost/student-friendly options: **Azure Static Web Apps** for the frontend.

---

## Recommended architecture (student-friendly)

- Frontend: Azure Static Web Apps (free tier for students). Integrates with GitHub Actions and provides CDN + SSL automatically. ✅
- Container images: push to **Azure Container Registry (ACR)** or use GHCR if you prefer (only necessary if you're packaging containers for custom infra).

---

## Prerequisites

- Azure subscription (student free account) for optional Terraform usage. 
- Azure CLI locally for manual steps (optional): `az`.
- GitHub repository admin rights to add repository Secrets and Actions.

---

## Required Azure resources & decisions

1. **Resource Group** (create in a nearby region, e.g., `eastus`) — used to group resources if you're using Terraform or managing resources manually.
2. **Azure Static Web App** — create via portal or via `az`/Terraform (recommended for frontend only).

---

## GitHub Secrets to add

- `AZURE_CREDENTIALS` - JSON created from `az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/<sub-id>/resourceGroups/<rg> --sdk-auth` (copy full JSON output). **Only required if you manage Azure resources via Terraform.**
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - required for Static Web Apps deploy via the `Azure/static-web-apps-deploy` action. Get it from Azure Portal → Static Web App → **Manage deployment token**. **You have already added this token; rotate it if you believe it was exposed.**
- `FRONTEND_API_BASE_URL` - (optional) set this to an API base URL if your static site needs to call a separate backend. The CI pipeline will inject this value into `frontend/public/index.html` at deploy time so the static site knows where to call that API.

**Note on npm lockfiles:** Our workflows now use `npm install` so CI won't fail if `package-lock.json` is not present. For reproducible, deterministic installs and faster CI, it is recommended to run `npm install` locally and commit the generated `package-lock.json` to the repository, then switch workflows back to `npm ci`.

**Note on builds for Azure Static Web Apps:** The workflow is configured to skip Oryx builds and directly upload the files in `frontend/public` (because your frontend is already a prebuilt static site). If in future you change to a framework that requires building (React/Vue/Next/etc.), add a `build` script to `frontend/package.json` (e.g., `"build": "react-scripts build"`) or set an explicit `app_build_command` in the workflow so Oryx will run your build step.
- `DOMAIN_NAME` - (recommended) add your custom domain (e.g., `projectapi.live`) as a repo secret so the deploy workflow can automatically verify the site after deploy.

**Security note:** You shared a Static Web Apps token in chat. Treat it as compromised: please **regenerate** it in the Azure Portal and add the new value to the GitHub secret `AZURE_STATIC_WEB_APPS_API_TOKEN`. Do not paste secrets into chat.

---

## CI/CD plan (short)

1. **CI**: Run tests on PRs (frontend npm test).
2. **Frontend CD**: On push to `main`, build and deploy `frontend/` to Azure Static Web Apps using `Azure/static-web-apps-deploy` action.

---

## Terraform notes

- This repo uses a local Terraform backend by default (good for single-user/student workflows).
- If you prefer to manage Azure resources with Terraform, switch the provider to `azurerm` and create a `resource_group`, `azure_static_site` (or `azurerm_static_site` if available), `azurerm_container_registry`, and `azurerm_container_instance` resources.

---

## Helpful commands

- Create service principal with sufficient scope:

```bash
az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group> --sdk-auth
```

- Create an ACR:

```bash
az acr create --resource-group <rg> --name <acr-name> --sku Standard
```

---

## Next steps for me

Tell me if you want me to:
- Scaffold GitHub Actions for Azure Static Web Apps + optional ACR/ACI deploy (I can add templates), or
- Convert `terraform/` to manage Azure resources with `azurerm` provider (I can scaffold a starter `main.tf`).

