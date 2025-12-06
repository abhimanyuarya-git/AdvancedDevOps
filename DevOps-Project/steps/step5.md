# Step-05: Add GitHub Credentials & Create Multibranch Pipeline in Jenkins

To enable Jenkins to securely interact with your GitHub repositories (e.g., clone, build, trigger jobs), you must add GitHub credentials and configure a **Multibranch Pipeline** job.

---

## 🔐 1. Log In to Jenkins Master

Open your browser and access Jenkins:

```
http://<jenkins-master-ip>:8080
```

Log in with your admin credentials.

---

## 🗂 2. Navigate to Credentials Management

- Go to **"Manage Jenkins"**.
- Select **"Manage Credentials"**.

---

## ➕ 3. Add GitHub Credentials

- Under the **"(global)"** domain (or another scope if preferred), click **"Add Credentials"**.

---

## 🔧 4. Select Credential Type

From the **Kind** dropdown, choose:

### ✅ **Username with Password**

Best suited for GitHub Personal Access Token (PAT) authentication.

- **Username:** Your GitHub username
- **Password:** A GitHub **Personal Access Token (PAT)**
- **ID (optional):** e.g., `github-pat-jenkins`
- **Description:** e.g., `GitHub PAT for Multibranch Pipeline`

> 📌 **How to Get a GitHub PAT:**
>
> - Go to GitHub → **Settings > Developer Settings > Personal Access Tokens**
> - Generate a new token with scopes:
>   - `repo` (for private repositories)
>   - `admin:repo_hook` (to manage webhooks)
>   - `read:user`, `workflow` (optional for extended integration)

---

## 💾 5. Save Credentials

Click **"OK"** or **"Save"** to store the credentials. Jenkins can now use these for GitHub access.

---

## 📦 6. Create a Multibranch Pipeline Job

- From the **Jenkins Dashboard**, click **"New Item"**
- Enter a job name (e.g., `my-github-ci`)
- Select **"Multibranch Pipeline"**
- Click **"OK"**

---

## 🔧 7. Configure Multibranch Pipeline

- Under the **"Branch Sources"** section:
  - Click **"Add source"** → Choose **GitHub**
  - Fill in:
    - **Repository URL:** `https://github.com/your-username/your-repo.git`
    - **Credentials:** Select the GitHub PAT credentials you added earlier

- (Optional) Configure:
  - **Build strategies** (e.g., build on new PRs, tags)
  - **Property strategies** for branches
  - **Repository owner** and **API endpoints** if using GitHub Enterprise

---

## 💾 8. Save Job Configuration

Click **"Save"** to finalize the setup.

Jenkins will now **scan the repository** and automatically create jobs for each branch and pull request that contains a valid `Jenkinsfile`.

---

## 🔁 9. Jenkinsfile in GitHub

Ensure that your repository contains a `Jenkinsfile` in each relevant branch. It defines the pipeline steps, such as:

```groovy
pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        echo 'Building...'
      }
    }
    stage('Test') {
      steps {
        echo 'Running tests...'
      }
    }
  }
}
```

---

## 🔔 10. (Optional) Enable GitHub Webhooks

To trigger builds automatically on new commits:

- Go to your GitHub repo → **Settings > Webhooks**
- Add a webhook pointing to:

  ```
  http://<jenkins-master-ip>:8080/github-webhook/
  ```

- Choose event types like: `push`, `pull_request`

Ensure the GitHub plugin is installed in Jenkins for webhook compatibility.

---

✅ **Result:** Jenkins now integrates with GitHub and automatically discovers, builds, and manages branches or PRs based on your pipeline logic—ideal for CI/CD workflows.