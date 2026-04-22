# <div align="center">HAKI Backend</div>

<div align="center">
  <p align="center">
    <strong>The scalable, high-performance core engine powering the HAKI chat ecosystem.</strong>
    <br />
    Built with NestJS 11, TypeScript, and PostgreSQL.
  </p>

  <p align="center">
    <a href="#-features">Features</a> •
    <a href="#-tech-stack">Tech Stack</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#-docker-support">Docker</a> •
    <a href="#-structure">Structure</a>
  </p>
</div>

---

## 🌟 Overview

**HAKI Backend** is a progressive Node.js server-side application designed for maximum efficiency and scalability. It serves as the central hub for the HAKI ecosystem, handling real-time communications, secure authentication, complex business logic for coupons and orders, and persistent data storage.

## 🚀 Features

### 💬 Real-time Communication
- **WebSocket Integration**: Low-latency, bidirectional communication powered by Socket.io.
- **Presence Tracking**: Real-time monitoring of user online/offline status.
- **Message Queuing**: Reliable delivery and synchronization across multiple clients.

### 🔐 Security & Identity
- **JWT Authentication**: Secure, stateless session management.
- **Role-Based Access Control (RBAC)**: Fine-grained permissions for Users, Business Admins, and Super Admins.
- **Bcrypt Encryption**: Industry-standard hashing for sensitive user data.

### 📊 Business Logic Engine
- **Coupon Orchestration**: Automated generation, validation, and redemption tracking.
- **Order Lifecycle**: Robust state machine for managing orders across various business units.
- **Open Graph Support**: Automated link preview generation for shared content.

### 🛠️ Engineering Excellence
- **Database Resilience**: TypeORM integration with PostgreSQL for reliable data persistence.
- **Structured Logging**: Comprehensive audit trails using Winston and Nest-Winston.
- **Scalable Architecture**: Modular design following NestJS best practices (Modules, Controllers, Services).

## 🛠️ Tech Stack

| Category | Technology |
| :--- | :--- |
| **Framework** | [NestJS 11](https://nestjs.com/) |
| **Runtime** | [Node.js 22+](https://nodejs.org/) |
| **Language** | [TypeScript](https://www.typescriptlang.org/) |
| **Database** | [PostgreSQL](https://www.postgresql.org/) |
| **ORM** | [TypeORM](https://typeorm.io/) |
| **Real-time** | [Socket.io](https://socket.io/) |
| **Logging** | [Winston](https://github.com/winstonjs/winston) |

## 📦 Getting Started

### Prerequisites
- **Node.js** (v22.x or higher)
- **PostgreSQL** (v15.x or higher)
- **npm** (v10.x or higher)

### Installation

1. **Clone & Install**
   ```bash
   git clone https://github.com/your-repo/haki-backend.git
   cd haki-backend
   npm install
   ```

2. **Environment Setup**
   Create a `.env` file based on your configuration:
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_USERNAME=postgres
   DB_PASSWORD=your_password
   DB_DATABASE=haki_db
   JWT_SECRET=your_super_secret_key
   ```

3. **Database Preparation**
   The application uses TypeORM synchronization in development. Ensure your database exists.

4. **Run Application**
   ```bash
   # Development mode
   npm run start:dev

   # Production mode
   npm run build
   npm run start:prod
   ```

## 🐳 Docker Support

HAKI Backend is fully containerized for easy deployment.

```bash
# Start the entire stack (App + PostgreSQL)
docker-compose up -d

# Build the production image
docker build -t haki-backend .
```

## 📁 Project Structure

```text
src/
├── modules/          # Business logic modules (Auth, Users, Orders, etc.)
├── common/           # Shared guards, interceptors, and decorators
├── config/           # Centralized configuration management
├── main.ts           # Application entry point
└── app.module.ts     # Root application module
```

## 📝 API Documentation

Once the server is running, you can explore the available endpoints.
- **Local Endpoint List**: Check `api-endpoints.md` for a comprehensive list of routes and payloads.

---

<div align="center">
  <p>Engineered with ❤️ by <strong>Muhammad Fathy</strong></p>
  <img src="https://img.shields.io/badge/NestJS-E0234E?style=flat-square&logo=nestjs&logoColor=white" alt="NestJS" />
  <img src="https://img.shields.io/badge/PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker" />
</div>
