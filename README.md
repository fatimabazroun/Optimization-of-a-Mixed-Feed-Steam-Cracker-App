# CrackX

A mobile application for simulating and optimizing mixed-feed steam cracking processes in petrochemical production. Built as a capstone project at King Fahd University of Petroleum and Minerals (KFUPM).

## Overview

CrackX allows process engineers and researchers to simulate thermal cracking scenarios, evaluate CO₂ emissions, assess geological CO₂ storage feasibility, and generate detailed PDF reports — all from a mobile device.

## Features

- **3 Cracking Scenarios** — Ethane-dominant (S1), Balanced mixed-feed (S2), Naphtha-rich (S3)
- **Simulation Results** — Ethylene yield, furnace reduction, cost savings, hydrogen purity, CO₂ rate
- **CO₂ Assessment** — Standalone scope 1/2/3 emissions evaluation
- **Reservoir Analysis** — Geological CO₂ storage feasibility with pressure and plume radius charts
- **Saved Scenarios** — Save, search, and revisit past simulations via AWS DynamoDB + S3
- **PDF Reports** — Auto-generated reports with charts, KPIs, and ISE recommendations
- **Dark Mode** — Full light/dark theme support
- **ISE Recommendations** — Industrial & Systems Engineering optimisation insights

## Tech Stack

### Frontend
- **Flutter** (iOS & Android)
- **AWS Amplify** — Authentication via Amazon Cognito
- **fl_chart** — Line and performance charts
- **printing** — Native PDF print/share sheet
- **package_info_plus** — Dynamic version display
- **shared_preferences** — Dark mode persistence

### Backend (AWS Lambda + API Gateway)
| Lambda | Purpose |
|--------|---------|
| `simulation_engine` | Runs cracking simulation and returns KPIs |
| `co2_assessment` | Evaluates CO₂ emission scopes |
| `scenario_manager` | Saves and retrieves scenarios (DynamoDB + S3) |
| `report_generator` | Generates PDF reports with charts |

### AWS Services
- **Cognito** — User authentication
- **API Gateway** — REST API endpoints
- **Lambda** — Serverless compute
- **DynamoDB** — Scenario metadata storage
- **S3** — Simulation results and PDF storage

## Project Structure

```
├── frontend/                  # Flutter app
│   ├── lib/
│   │   ├── core/              # Theme, services, utilities
│   │   ├── features/          # Auth, workspace, saved, account screens
│   │   └── shared/            # Reusable widgets
│   └── assets/
│       └── images/            # App logo and assets
└── backend/
    └── lambdas/
        ├── simulation_engine/
        ├── co2_assessment/
        ├── scenario_manager/
        └── report_generator/
```

## Getting Started

### Prerequisites
- Flutter 3.x
- Dart 3.x
- AWS account with Cognito, Lambda, DynamoDB, S3, and API Gateway configured

### Setup

1. Clone the repository
```bash
git clone https://github.com/fatimabazroun/Optimization-of-a-Mixed-Feed-Steam-Cracker-App.git
cd Optimization-of-a-Mixed-Feed-Steam-Cracker-App
```

2. Copy the environment file and fill in your AWS endpoints
```bash
cp frontend/.env.example frontend/.env
```

3. Copy the Amplify configuration and add your Cognito details
```bash
cp frontend/lib/amplifyconfiguration.example.dart frontend/lib/amplifyconfiguration.dart
```

4. Install Flutter dependencies
```bash
cd frontend
flutter pub get
```

5. Run the app
```bash
flutter run
```

### Deploying a Lambda

```bash
cd backend/lambdas/<lambda_name>
bash package.sh
# Upload the generated .zip to AWS Lambda via console or CLI
```

## Development Team

| Name | Department |
|------|-----------|
| Fatima Bazroun | Software Engineering |
| Joud Almatrood | Chemical Engineering |
| Zainab Alamer | Chemical Engineering |
| Safana Aljughaiman | Industrial & Systems Engineering |
| Munirah Alobaid | Industrial & Systems Engineering |
| Dona Alsaud | Petroleum Engineering |

**Institution:** King Fahd University of Petroleum and Minerals (KFUPM) · Dhahran, Saudi Arabia

## Version

v1.0.0 — April 2026
