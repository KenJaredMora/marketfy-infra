# Marketfy - Full-Stack E-Commerce Platform

A complete e-commerce platform with dual frontend implementations (Angular & React), NestJS backend, and AWS deployment infrastructure.

## 🚀 Live Demo

- **Angular Frontend**: <http://marketfy-alb-1492993669.us-east-1.elb.amazonaws.com/>
- **React Frontend**: <http://marketfy-alb-1492993669.us-east-1.elb.amazonaws.com/react/products>
- **API**: <http://marketfy-alb-1492993669.us-east-1.elb.amazonaws.com/api/products>

**Demo Credentials:**

- Email: `demo@marketfy.test`
- Password: `password123`

## 📁 Project Structure

```MD
Proyecto Deloitte Java/
├── angular-project/
│   ├── marketfy/           # Angular frontend
│   └── marketfy-api/       # NestJS backend API
├── marketfy-react/         # React frontend
└── marketfy-infra/         # AWS infrastructure (Terraform + Docker)
    ├── terraform/          # Infrastructure as Code
    ├── docker/            # Dockerfiles for all services
    └── docs/              # Deployment documentation
```

## 🛠️ Tech Stack

### Backend

- **NestJS 11** - Progressive Node.js framework
- **PostgreSQL** - Relational database
- **Prisma 6** - Modern ORM
- **JWT + Passport** - Authentication
- **bcrypt** - Password hashing

### Frontend (Angular)

- **Angular 19** - Component-based framework
- **TypeScript** - Type-safe JavaScript
- **RxJS** - Reactive programming
- **Angular Material** - UI components

### Frontend (React)

- **React 18** - UI library
- **Redux Toolkit** - State management
- **Material-UI** - Component library
- **React Router v6** - Routing
- **Axios** - HTTP client

### Infrastructure

- **AWS ECS (EC2)** - Container orchestration
- **AWS RDS** - Managed PostgreSQL
- **AWS ECR** - Container registry
- **Application Load Balancer** - Traffic distribution
- **Terraform** - Infrastructure as Code
- **Docker** - Containerization

## ✨ Features

- ✅ JWT-based authentication
- ✅ Product catalog with search, filtering, and pagination
- ✅ Shopping cart (localStorage)
- ✅ Wishlist (backend-synced)
- ✅ Order management and history
- ✅ User profile management
- ✅ Responsive design (mobile-first)
- ✅ Security: Helmet, CORS, rate limiting
- ✅ Database seeding with 30 products
- ✅ Production-ready deployment on AWS

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- Docker Desktop
- AWS CLI (for deployment)
- Terraform (for infrastructure)

### Local Development

#### 1. Backend API

```bash
cd angular-project/marketfy-api
npm install
cp .env.example .env
# Edit .env with your database credentials
npm run prisma:migrate
npm run seed
npm run start:dev
```

API runs at: <http://localhost:3000>

#### 2. Angular Frontend

```bash
cd angular-project/marketfy
npm install
npm start
```

Angular app runs at: <http://localhost:4200>

#### 3. React Frontend

```bash
cd marketfy-react
npm install
npm run dev
```

React app runs at: <http://localhost:5173>

## 🏗️ AWS Deployment

The application is deployed on AWS using:

- **ECS on EC2** (t3.medium instances)
- **RDS PostgreSQL** (t3.micro)
- **Application Load Balancer** with path-based routing
- **ECR** for Docker images

### Deployment Architecture

```md
Internet → ALB → ECS Cluster
                  ├── API Service (Port 3000)
                  ├── Angular Service (Port 80)
                  └── React Service (Port 80)
                        ↓
                   RDS PostgreSQL
```

### Path Routing

- `/api/*` → Backend API
- `/angular/*` → Angular SPA
- `/react/*` → React SPA
- `/health` → Health check endpoint

For detailed deployment instructions, see [marketfy-infra/README.md](marketfy-infra/README.md)

## 📚 Documentation

- [Backend API Documentation](angular-project/marketfy-api/README.md)
- [Angular Frontend Guide](angular-project/marketfy/README.md)
- [React Frontend Guide](marketfy-react/README.md)
- [Infrastructure & Deployment](marketfy-infra/README.md)
- [Terraform Documentation](marketfy-infra/terraform/README.md)

## 🔐 Security

- No hardcoded credentials
- Environment variables for sensitive data
- JWT tokens with secure secrets
- Password hashing with bcrypt (10 rounds)
- Security headers via Helmet
- Rate limiting (100 req/min)
- CORS properly configured
- Security groups with minimal permissions
- Private database subnets

## 🧪 Testing

### Backendd

```bash
cd angular-project/marketfy-api
npm run test
npm run test:e2e
```

### Angular

```bash
cd angular-project/marketfy
npm test
```

### React

```bash
cd marketfy-react
npm run test
```

## 📊 Database Schema

- **User**: Authentication, profile, interests
- **Product**: Name, price, description, tags, images
- **Order**: Order history with line items
- **WishlistItem**: User favorites

Database includes 30 seeded products across categories:

- Electronics
- Home & Kitchen
- Fitness & Sports
- Fashion
- Gaming

## 🤝 Contributing

This is a private project. For internal contributions:

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## 📝 License

UNLICENSED - Private project

## 👥 Authors

Kenyon Jared Mora Zamora

## 🆘 Support

For issues or questions:

1. Check the relevant README in each directory
2. Review CloudWatch logs for deployed services
3. Consult AWS ECS console for container status

---

**Last Updated**: November 2025
**Status**: Production deployment active on AWS
