# <div align="center">HAKI Admin Dashboard</div>

<div align="center">
  <img src="./public/banner.png" alt="HAKI Dashboard Banner" width="100%" />
</div>

<div align="center">
  <p align="center">
    <strong>A high-performance, premium administrative interface for the HAKI ecosystem.</strong>
    <br />
    Built with Next.js 15, React 19, and Tailwind CSS 4.
  </p>

  <p align="center">
    <a href="#-features">Features</a> •
    <a href="#-tech-stack">Tech Stack</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#-project-structure">Structure</a>
  </p>
</div>

---

## 🌟 Overview

The **HAKI Admin Dashboard** is a state-of-the-art management console designed to provide real-time insights and control over the HAKI chat platform. It offers a seamless experience for administrators to monitor user activity, manage orders, generate coupons, and oversee system health with elegant visualizations and a responsive interface.

## 🚀 Features

### 📊 Advanced Analytics
- **Real-time Growth Tracking**: Monitor user acquisition and message volume in real-time.
- **Interactive Visualizations**: High-fidelity charts powered by Recharts for data-driven decision making.
- **Business Insights**: Specific metrics tailored for individual business units within the HAKI ecosystem.

### 🎫 Coupon & Promotion Management
- **Bulk Generation**: Sophisticated logic for creating unique, business-prefixed coupon codes.
- **Flexible Distribution**: Manage coupon lifecycle from creation to redemption tracking.
- **Custom Prefixes**: Automatically generate codes like `SHOP-ABC-123` for brand consistency.

### 📦 Order & Logistics Control
- **Unified Order View**: Track orders across all businesses in a single, powerful interface.
- **Status Management**: Real-time updates for order processing, from placement to completion.
- **Detailed Drill-downs**: Deep-dive into specific order metadata and history.

### 🛡️ Super Admin Capabilities
- **User Governance**: Comprehensive tools for role management and account moderation (ban/unban).
- **System Monitoring**: Access to backend logs and storage usage statistics.
- **Global Broadcasts**: Send instant announcements to all connected users across the platform.

## 🛠️ Tech Stack

| Category | Technology |
| :--- | :--- |
| **Framework** | [Next.js 15+](https://nextjs.org/) (App Router) |
| **Core** | [React 19](https://react.dev/) |
| **Styling** | [Tailwind CSS 4](https://tailwindcss.com/) |
| **Data Viz** | [Recharts](https://recharts.org/) |
| **Icons** | [Lucide React](https://lucide.dev/) |
| **Language** | [TypeScript](https://www.typescriptlang.org/) |

## 📦 Getting Started

### Prerequisites

Ensure you have the following installed:
- **Node.js**: v20 or higher
- **npm**: v10 or higher
- **Backend**: A running instance of the [HAKI Backend](https://github.com/your-repo/haki-backend)

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-repo/haki-dashboard.git
   cd haki-dashboard
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**
   Create a `.env.local` file in the root directory:
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:3000
   ```

4. **Run Development Server**
   ```bash
   npm run dev
   ```

Visit [http://localhost:3001](http://localhost:3001) to explore the dashboard.

## 📁 Project Structure

```text
haki-dashboard/
├── src/
│   ├── app/            # Next.js App Router (Pages, Layouts, CSS)
│   ├── components/     # High-fidelity UI Components
│   ├── lib/            # Core logic, API clients & Utilities
│   └── types/          # Global TypeScript definitions
├── public/             # Static assets (Images, Icons)
└── next.config.ts      # Optimized Next.js configuration
```

## 🔐 Security & Access

For development environments, use the following pre-configured credentials:
- **Username**: `admin`
- **Password**: `admin123`

> [!WARNING]
> Always change default credentials and rotate API keys before deploying to production environments.

---

<div align="center">
  <p>Built with precision by <strong>Muhammad Fathy</strong></p>
  <img src="https://img.shields.io/badge/Made%20with-React-61DAFB?style=flat-square&logo=react" alt="Made with React" />
  <img src="https://img.shields.io/badge/Styled%20with-Tailwind-38B2AC?style=flat-square&logo=tailwind-css" alt="Styled with Tailwind" />
</div>
