<div align="center">

# 🏥 מערכת CRM למרפאה פרטית

### Doctor Clinic CRM — Full-Stack Demo Application

מערכת ניהול מרפאה חכמה עם בינה מלאכותית, חיזוי נטישת מטופלים וצ'אט RAG

[![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python&logoColor=white)](https://python.org)
[![Flask](https://img.shields.io/badge/Flask-3.1-000000?logo=flask&logoColor=white)](https://flask.palletsprojects.com)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o-412991?logo=openai&logoColor=white)](https://openai.com)
[![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-CDN-06B6D4?logo=tailwindcss&logoColor=white)](https://tailwindcss.com)

</div>

---

## 📸 צילומי מסך

<div align="center">

### לוח בקרה ראשי
![Dashboard](frontend/static/images/screenshots/dashboard.png)

### פרופיל מטופל + היסטוריה רפואית
![Patient Profile](frontend/static/images/screenshots/patient-profile.png)

### לוח משימות (Kanban)
![Kanban Board](frontend/static/images/screenshots/kanban.png)

</div>

---

## 🏗️ ארכיטקטורת המערכת

```mermaid
graph TB
    subgraph Client ["🖥️ Frontend"]
        Browser["דפדפן"]
        Tailwind["Tailwind CSS CDN"]
        ChartJS["Chart.js"]
        SortableJS["SortableJS"]
    end

    subgraph Server ["⚙️ Backend - Flask"]
        App["app.py"]
        Routes["Routes / Blueprints"]
        Services["Services Layer"]
        Middleware["Auth Middleware"]
        Churn["Churn Model<br/>scikit-learn"]
    end

    subgraph External ["☁️ External Services"]
        Supabase["Supabase<br/>PostgreSQL"]
        OpenAI["OpenAI API<br/>GPT-4o / GPT-4o-mini"]
    end

    Browser -->|HTTP/AJAX| App
    App --> Routes
    Routes --> Middleware
    Middleware --> Services
    Services --> Supabase
    Services --> OpenAI
    Services --> Churn
    Browser --> Tailwind
    Browser --> ChartJS
    Browser --> SortableJS

    style Client fill:#EFF6FF,stroke:#197fe6,stroke-width:2px
    style Server fill:#F0FDF4,stroke:#078838,stroke-width:2px
    style External fill:#FFF7ED,stroke:#f59e0b,stroke-width:2px
```

---

## 🔄 תהליך אימות והרשאות

```mermaid
sequenceDiagram
    participant U as 👤 משתמש
    participant F as 🖥️ Frontend
    participant A as 🔐 Auth Route
    participant S as 📦 Auth Service
    participant DB as 🗄️ Supabase

    U->>F: כניסה (email + password)
    F->>A: POST /login
    A->>S: authenticate_user()
    S->>DB: SELECT * FROM users WHERE email=?
    DB-->>S: user record
    S->>S: verify_password (werkzeug pbkdf2)
    S-->>A: user data / None

    alt הצלחה
        A->>A: session[user_id, user_role, user_name]
        A-->>F: redirect → /dashboard
        F-->>U: לוח בקרה
    else כישלון
        A-->>F: flash error
        F-->>U: "אימייל או סיסמה שגויים"
    end
```

---

## 🤖 ארכיטקטורת RAG Chat

```mermaid
flowchart LR
    Q["❓ שאלה בעברית<br/>'כמה תורים יש השבוע?'"]

    SQL_GEN["🧠 GPT-4o<br/>NL → SQL"]

    GUARD["🛡️ Guardrails<br/>• SELECT only<br/>• No medical_history<br/>• No password_hash<br/>• Max 100 rows"]

    EXEC["⚡ Execute SQL<br/>Supabase RPC"]

    ANS_GEN["💬 GPT-4o-mini<br/>Results → Hebrew Answer"]

    RESPONSE["✅ תשובה<br/>'השבוע יש 12 תורים מתוזמנים'"]

    Q --> SQL_GEN --> GUARD

    GUARD -->|✅ Valid| EXEC --> ANS_GEN --> RESPONSE
    GUARD -->|❌ Blocked| BLOCK["⛔ שאילתה נחסמה"]

    style Q fill:#EFF6FF,stroke:#197fe6
    style SQL_GEN fill:#F3E8FF,stroke:#7c3aed
    style GUARD fill:#FEF2F2,stroke:#e73908
    style EXEC fill:#F0FDF4,stroke:#078838
    style ANS_GEN fill:#F3E8FF,stroke:#7c3aed
    style RESPONSE fill:#F0FDF4,stroke:#078838
    style BLOCK fill:#FEF2F2,stroke:#e73908
```

---

## 📊 מודל חיזוי נטישה (Churn Prediction)

```mermaid
flowchart TD
    subgraph Features ["📐 Feature Engineering"]
        F1["ימים מאז ביקור אחרון"]
        F2["סה״כ תורים"]
        F3["שיעור ביטולים"]
        F4["סה״כ הכנסות"]
        F5["מרווח ממוצע בין ביקורים"]
    end

    subgraph Model ["🤖 Logistic Regression"]
        LR["scikit-learn<br/>LogisticRegression"]
    end

    subgraph Output ["📊 Output"]
        SCORE["Churn Probability %"]
        HIGH["🔴 גבוהה > 70%"]
        MED["🟡 בינונית 40-70%"]
        LOW["🟢 נמוכה < 40%"]
    end

    F1 & F2 & F3 & F4 & F5 --> LR
    LR --> SCORE
    SCORE --> HIGH
    SCORE --> MED
    SCORE --> LOW

    style Features fill:#EFF6FF,stroke:#197fe6
    style Model fill:#F3E8FF,stroke:#7c3aed
    style Output fill:#FFF7ED,stroke:#f59e0b
```

---

## 🗂️ מבנה הפרויקט

```mermaid
graph LR
    subgraph Root ["📁 CRM/"]
        APP["app.py"]
        REQ["requirements.txt"]
        ENV[".env"]
    end

    subgraph Backend ["📁 backend/"]
        INIT["__init__.py<br/>Flask Factory"]

        subgraph Routes ["routes/"]
            R1["auth.py"]
            R2["dashboard.py"]
            R3["patients.py"]
            R4["services.py"]
            R5["appointments.py"]
            R6["invoices.py"]
            R7["tasks.py"]
            R8["chat.py"]
        end

        subgraph Svc ["services/"]
            S1["auth_service"]
            S2["dashboard_service"]
            S3["patient_service"]
            S4["chat_service"]
            S5["churn_service"]
        end

        subgraph Seed ["seed/"]
            SCHEMA["schema.sql"]
            SEEDPY["seed_data.py"]
        end
    end

    subgraph Frontend ["📁 frontend/"]
        subgraph Templates ["templates/"]
            BASE["base.html"]
            T1["dashboard/"]
            T2["patients/"]
            T3["services/"]
            T4["appointments/"]
            T5["invoices/"]
            T6["tasks/kanban"]
            T7["chat/"]
        end

        subgraph Static ["static/"]
            CSS["css/custom.css"]
            JS1["js/utils.js"]
            JS2["js/dashboard-charts.js"]
            JS3["js/kanban.js"]
            JS4["js/chat.js"]
        end
    end

    style Root fill:#f8fafc,stroke:#334155
    style Backend fill:#F0FDF4,stroke:#078838
    style Frontend fill:#EFF6FF,stroke:#197fe6
```

---

## 🗄️ סכמת מסד הנתונים (ERD)

```mermaid
erDiagram
    USERS {
        uuid id PK
        varchar email UK
        varchar password_hash
        varchar full_name
        varchar role "doctor | secretary"
        timestamp created_at
    }

    PATIENTS {
        uuid id PK
        varchar first_name
        varchar last_name
        varchar id_number UK
        date date_of_birth
        varchar gender
        varchar phone
        varchar email
        text address
        timestamp created_at
    }

    MEDICAL_HISTORY {
        uuid id PK
        uuid patient_id FK
        text_arr diagnoses
        text_arr medications
        text_arr allergies
        text chronic_conditions
        text notes
        timestamp updated_at
    }

    SERVICES {
        uuid id PK
        varchar name
        text description
        decimal price
        int duration_minutes
        boolean is_active
    }

    APPOINTMENTS {
        uuid id PK
        uuid patient_id FK
        uuid service_id FK
        uuid doctor_id FK
        timestamp appointment_date
        varchar status "scheduled | completed | cancelled | no_show"
        text notes
    }

    INVOICES {
        uuid id PK
        varchar invoice_number UK
        uuid patient_id FK
        uuid appointment_id FK
        decimal amount
        varchar status "paid | pending | overdue"
        date issued_date
        date paid_date
    }

    TASKS {
        uuid id PK
        varchar title
        text description
        varchar status "open | in_progress | done"
        varchar priority "urgent | medium | normal"
        uuid assigned_to FK
        date due_date
        int position
    }

    PATIENTS ||--o{ MEDICAL_HISTORY : "has"
    PATIENTS ||--o{ APPOINTMENTS : "books"
    PATIENTS ||--o{ INVOICES : "billed"
    SERVICES ||--o{ APPOINTMENTS : "offered in"
    USERS ||--o{ APPOINTMENTS : "doctor"
    APPOINTMENTS ||--o| INVOICES : "generates"
    USERS ||--o{ TASKS : "assigned to"
```

---

## ✨ פיצ'רים

| פיצ'ר | תיאור | טכנולוגיה |
|--------|--------|-----------|
| 🔐 **אימות משתמשים** | כניסה עם אימייל/סיסמה, הרשאות לפי תפקיד | Flask Sessions, werkzeug |
| 📊 **לוח בקרה** | 4 כרטיסי KPI, גרף הכנסות, גרף סטטוס תורים | Chart.js |
| 🤖 **חיזוי נטישה** | מודל ML לזיהוי מטופלים בסיכון | scikit-learn |
| 👥 **ניהול מטופלים** | CRUD מלא + פרופיל מפורט + היסטוריה רפואית | Supabase |
| 🩺 **שירותים** | ניהול קטלוג שירותי המרפאה | Supabase |
| 📅 **תורים** | ניהול תורים עם סינון סטטוס | Supabase |
| 💳 **חשבוניות** | ניהול חשבוניות עם סימון תשלום מהיר | Supabase |
| ✅ **לוח משימות** | Kanban עם גרירה בין עמודות | SortableJS |
| 💬 **צ'אט AI** | שאלות בשפה טבעית על נתוני המרפאה | OpenAI GPT-4o RAG |

---

## 👥 תפקידים והרשאות

```mermaid
graph LR
    subgraph Doctor ["🩺 רופא — גישה מלאה"]
        D1["לוח בקרה + חיזוי נטישה"]
        D2["מטופלים + היסטוריה רפואית"]
        D3["שירותים / תורים / חשבוניות"]
        D4["לוח משימות"]
        D5["צ'אט AI"]
    end

    subgraph Secretary ["📋 מזכירות — גישה מוגבלת"]
        S1["לוח בקרה (ללא חיזוי)"]
        S2["מטופלים (ללא היסטוריה רפואית)"]
        S3["שירותים / תורים / חשבוניות"]
        S4["לוח משימות"]
        S5["❌ אין גישה לצ'אט AI"]
    end

    style Doctor fill:#F0FDF4,stroke:#078838,stroke-width:2px
    style Secretary fill:#FFF7ED,stroke:#f59e0b,stroke-width:2px
    style S5 fill:#FEF2F2,stroke:#e73908
```

---

## 🚀 התקנה והפעלה

### דרישות מקדימות
- Python 3.11+
- חשבון [Supabase](https://supabase.com) (חינמי)
- מפתח [OpenAI API](https://platform.openai.com)

### שלבים

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/crm-doctor.git
cd crm-doctor

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment variables
cp .env.example .env
# Edit .env with your Supabase and OpenAI keys

# 5. Create database tables
# Copy contents of backend/seed/schema.sql
# Paste and run in Supabase SQL Editor

# 6. Populate dummy data
python -m backend.seed.seed_data

# 7. Run the application
python app.py
```

Open [http://localhost:5000](http://localhost:5000) in your browser.

### 🔑 Demo Credentials

| תפקיד | אימייל | סיסמה |
|--------|--------|--------|
| רופא | `doctor@demo.com` | `demo1234` |
| מזכירות | `secretary@demo.com` | `demo1234` |

---

## 🎨 מערכת עיצוב

| Token | ערך | שימוש |
|-------|------|-------|
| 🔵 Primary | `#197fe6` | כפתורים, לינקים, אלמנטים פעילים |
| 🟢 Success | `#078838` | סטטוס חיובי, הושלם, שולם |
| 🟡 Warning | `#f59e0b` | עדיפות בינונית, בהמתנה |
| 🔴 Danger | `#e73908` | דחוף, בוטל, באיחור |
| 📝 Font | Heebo + Manrope | Google Fonts |
| 🎯 Icons | Material Symbols Outlined | Google Fonts |
| 🖼️ UI Framework | Tailwind CSS | CDN |

---

## 🛠️ טכנולוגיות

```mermaid
mindmap
  root((CRM Doctor))
    Backend
      Python 3.11+
      Flask 3.1
      Supabase Python Client
      OpenAI SDK
      scikit-learn
      werkzeug
    Frontend
      Jinja2 Templates
      Tailwind CSS CDN
      Chart.js
      SortableJS
      Material Symbols
    Database
      Supabase
      PostgreSQL
      RPC Functions
    AI/ML
      GPT-4o — NL to SQL
      GPT-4o-mini — Answer Generation
      Logistic Regression — Churn
    Deployment
      Railway
      Gunicorn
```

---

## 📝 רישיון

This project is for **demo purposes only**.

---

<div align="center">

Built with ❤️ using Flask, Supabase, and OpenAI

</div>
