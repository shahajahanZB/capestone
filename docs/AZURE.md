# Azure Deployment Guide (Student Account) 🔷

This guide explains how to deploy the mostly-frontend application to **Azure** using GitHub Actions. It focuses on low-cost/student-friendly options: **Azure Static Web Apps** for the frontend and **Azure Container Registry (ACR) + Azure Container Instances (ACI)** for the backend container if needed.

---

## Recommended architecture (student-friendly)

- Frontend: Azure Static Web Apps (free tier for students). Integrates with GitHub Actions and provides CDN + SSL automatically. ✅
- Backend (optional): Azure Container Instance (ACI) or Azure App Service for Containers. ACI is simpler for small containers and pay-as-you-go. ⚠️ Monitor usage (student limits).
- Container images: push to **Azure Container Registry (ACR)** or use GHCR if you prefer.

---

## Prerequisites

- Azure subscription (student free account) with enough quota for one ACI instance. 
- Azure CLI locally for manual steps (optional): `az`.
- GitHub repository admin rights to add repository Secrets and Actions.

---

## Required Azure resources & decisions

1. **Resource Group** (create in a nearby region, e.g., `eastus`) — used to group ACR, ACI, or Static Web App.
2. **Azure Static Web App** — create via portal or via `az`/Terraform (recommended for frontend only).
3. **ACR (optional)** — if you want to publish backend container images to Azure.
4. **ACI (optional)** — to run the backend Docker container if you do not want to host the backend as a serverless API.

---

## GitHub Secrets to add

- `AZURE_CREDENTIALS` - JSON created from `az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/<sub-id>/resourceGroups/<rg> --sdk-auth` (copy full JSON output). **Only required if you deploy backend or manage Azure resources via Terraform.**
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - required for Static Web Apps deploy via the `Azure/static-web-apps-deploy` action. Get it from Azure Portal → Static Web App → **Manage deployment token**. **You have already added this token; rotate it if you believe it was exposed.**
- `FRONTEND_API_BASE_URL` - (optional) set this to the backend API base URL (e.g., `https://api.projectapi.live` or `https://<your-backend>.azurecontainer.io`). The CI pipeline will inject this value into `frontend/public/index.html` at deploy time so the static site knows where to call the backend API.
- `DOMAIN_NAME` - (recommended) add your custom domain (e.g., `projectapi.live`) as a repo secret so the deploy workflow can automatically verify the site after deploy.

- If using ACR/ACI:
  - `ACR_NAME` - Azure Container Registry name
  - `ACR_LOGIN_SERVER` - e.g., `myacr.azurecr.io`
  - `AZURE_RG` - Resource group name

**Security note:** You shared a Static Web Apps token in chat. Treat it as compromised: please **regenerate** it in the Azure Portal and add the new value to the GitHub secret `AZURE_STATIC_WEB_APPS_API_TOKEN`. Do not paste secrets into chat.

---

## CI/CD plan (short)

1. **CI**: Run tests on PRs (backend pytest, frontend npm test).
2. **Frontend CD**: On push to `main`, build and deploy `frontend/` to Azure Static Web Apps using `Azure/static-web-apps-deploy` action.
3. **Backend CD (optional)**: Build Docker image, push to ACR, then create or update an ACI instance using `az container create` or `az container restart`.

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

- Create an ACI instance from an image in ACR:

```bash
az container create --resource-group <rg> --name backend --image <acr-login-server>/backend:TAG --cpu 1 --memory 1 --ports 8000
```

---

## Next steps for me

Tell me if you want me to:
- Scaffold GitHub Actions for Azure Static Web Apps + optional ACR/ACI deploy (I can add templates), or
- Convert `terraform/` to manage Azure resources with `azurerm` provider (I can scaffold a starter `main.tf`).

