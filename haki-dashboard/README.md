# HAKI Admin Dashboard

A comprehensive administrative interface for the HAKI chat application. Built with Next.js, this dashboard provides real-time insights, user management, and system monitoring capabilities.

## 🚀 Features

- **Analytics Dashboard**: Visualize user growth and message volume with interactive charts.
- **User Management**: Monitor user activity, manage roles, and handle account status (ban/unban).
- **System Logs**: Real-time access to backend system logs for monitoring and debugging.
- **Storage Management**: Track storage usage and perform cleanup operations.
- **Broadcast System**: Send system-wide announcements to all users.

## 🛠️ Technology Stack

- **Framework**: [Next.js 15+](https://nextjs.org/) (App Router)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **Charts**: [Recharts](https://recharts.org/)
- **State Management**: React Hooks
- **Icons**: Lucide React

## 📦 Getting Started

### Prerequisites

This dashboard requires the [HAKI Backend](https://github.com/your-repo/haki-backend) to be running. By default, it expects the backend at `http://localhost:3000`.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/haki-dashboard.git
   cd haki-dashboard
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Configure environment variables (if necessary):
   Create a `.env.local` file if you need to override the default API URL:
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:3000
   ```

4. Run the development server:
   ```bash
   npm run dev
   ```

Open [http://localhost:3001](http://localhost:3001) (or the port assigned by Next.js) to see the dashboard.

## 🔐 Default Credentials

For development environments, you can use the default administrator account:

- **Username**: `admin`
- **Password**: `admin123`

*Note: Ensure you change these credentials in production environments.*

## 📁 Project Structure

- `src/app`: Next.js App Router pages and layouts.
- `src/components`: Reusable UI components.
- `src/lib`: API client and utility functions.
- `public`: Static assets.

---

Built with ❤️ by the HAKI Team.
