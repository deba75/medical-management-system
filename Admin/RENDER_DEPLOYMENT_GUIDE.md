# How to Deploy MediConnect Web Portal to Render.com (Step-by-Step)

This guide walks you through hosting your Flask Web Project (**Admin, Doctor, and Diagnostic Centre Web Portals**) live on **Render.com** (Free Web Service).

---

## Step 1: Prerequisites Check

Ensure the following files exist in your `Admin/` directory (already created for you):
1. **`requirements.txt`**: Contains `Flask`, `gunicorn`, `firebase-admin`, `Werkzeug`, etc.
2. **`Procfile`**: Contains `web: gunicorn app:app`.
3. **`app.py`**: Your Python Flask web application.

---

## Step 2: Push Your Code to GitHub / GitLab

1. Commit your project and push it to a GitHub or GitLab repository:
   ```bash
   git add .
   git commit -m "Add Render web deployment configuration for MediConnect"
   git push origin main
   ```
   *(Note: Do NOT push `serviceAccountKey.json` to public repositories. We will configure it as a Secret on Render below).*

---

## Step 3: Create a New Web Service on Render.com

1. Go to [https://dashboard.render.com/](https://dashboard.render.com/) and log in or sign up.
2. Click the **New +** button at the top right and select **Web Service**.
3. Connect your **GitHub** or **GitLab** account and select your repository (`telemedicine`).

---

## Step 4: Configure the Render Web Service Settings

Fill in the deployment settings on Render as follows:

| Field Name | Value to Enter |
| :--- | :--- |
| **Name** | `mediconnect-web-portal` |
| **Region** | Select nearest location (e.g., *Singapore* or *Oregon*) |
| **Branch** | `main` (or your active git branch) |
| **Root Directory** | `Admin` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `gunicorn app:app` |
| **Instance Type** | `Free` |

---

## Step 5: Add Firebase Secret Key (Environment Variables)

To connect live with your Firebase Firestore database on Render:

1. Scroll down to **Environment Variables** (or **Secret Files**).
2. Click **Add Environment Variable**:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT_JSON`
   - **Value**: Open your local `serviceAccountKey.json` file, copy the entire JSON text, and paste it here.
3. (Optional) Add another Environment Variable for Secret Key:
   - **Key**: `SECRET_KEY`
   - **Value**: Enter any secure random secret key string.

*Alternative (Secret File)*:
- Under **Secret Files**, click **Add Secret File**.
- **Filename**: `serviceAccountKey.json`
- **Contents**: Paste contents of `serviceAccountKey.json`.

---

## Step 6: Deploy & Access Your Live Web App

1. Click **Create Web Service**.
2. Render will automatically build your app (`pip install -r requirements.txt`) and start Gunicorn (`gunicorn app:app`).
3. Within 1–2 minutes, Render will output a live URL (e.g. `https://mediconnect-web-portal.onrender.com`).

---

## Step 7: Verify Live Access

Open your live Render URL in any web browser:
- **Web Gateway Login**: `https://mediconnect-web-portal.onrender.com/login`
- **Doctor Sign Up**: `https://mediconnect-web-portal.onrender.com/register/doctor`
- **Diagnostic Centre Sign Up**: `https://mediconnect-web-portal.onrender.com/register/diagnostic`
