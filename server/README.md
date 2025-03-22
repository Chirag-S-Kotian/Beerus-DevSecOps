
---

# CDrive - Backend

Welcome to the **CDrive** backend repository! CDrive is a cloud-based file storage system that allows users to upload, store, and manage files securely. This backend service handles user authentication, file management, and secure integration with **Cloudinary** for file storage.

## Features

- **User Authentication**: Register, login, and email verification using OTP.
- **File Management**: Upload, update, retrieve, and delete files securely.
- **Cloud Integration**: Stores files using **Cloudinary**.
- **Authentication Middleware**: Ensures that only authorized users can perform certain actions.

## Table of Contents

1. [Technologies Used](#technologies-used)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Environment Variables](#environment-variables)
5. [API Endpoints](#api-endpoints)
6. [Inspiration](#inspiration)
7. [Author](#author)

## Technologies Used

- **Node.js**: Server-side JavaScript runtime.
- **Express**: Web framework for Node.js.
- **Prisma**: ORM for interacting with the database.
- **PostgreSQL**: Relational database.
- **Cloudinary**: Cloud-based image and file management.
- **JWT**: For secure authentication.
- **Multer**: For handling file uploads.
- **Nodemailer**: For sending email verifications.

## Installation

Follow these steps to set up the backend on your local machine:

### 1. Clone the repository

```bash
git clone https://github.com/Chirag-S-Kotian/server.git
```

### 2. Navigate to the project directory

```bash
cd server
```

### 3. Install dependencies

```bash
npm install
```

### 4. Set up environment variables

Create a `.env` file in the root of your project and add the following variables:

```bash
DATABASE_URL=your_postgresql_database_url
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
MAIL_USER=your_email_address_for_sending_verifications
MAIL_PASSWORD=your_email_password
```

### 5. Set up the database

Run Prisma migrations to set up the PostgreSQL database:

```bash
npx prisma migrate dev
```

### 6. Start the server

```bash
npm run dev
```

The server will start running on `http://localhost:4000`.

## Usage

Once your server is up and running, you can interact with the backend via API endpoints.

### 1. **User Registration and Login**

- **Register**: POST `/api/users/register`
- **Login**: POST `/api/users/login`
- **Verify OTP**: POST `/api/users/verify`

### 2. **File Management**

- **Upload File**: POST `/api/files/upload`
- **Get All Files**: GET `/api/files`
- **Get File by ID**: GET `/api/files/:id`
- **Update File**: PUT `/api/files/:id`
- **Delete File**: DELETE `/api/files/:id`

## Environment Variables

To run this project, you will need to set the following environment variables in your `.env` file:

- `DATABASE_URL`: Your PostgreSQL connection URL.
- `JWT_SECRET`: A secret key for generating JSON Web Tokens.
- `CLOUDINARY_CLOUD_NAME`: Your Cloudinary account name.
- `CLOUDINARY_API_KEY`: Your Cloudinary API key.
- `CLOUDINARY_API_SECRET`: Your Cloudinary API secret.
- `MAIL_USER`: The email address used to send OTPs.
- `MAIL_PASSWORD`: The password for the email account.

## API Endpoints

Here are the main routes available:

### User Routes (`/api/users`)

| Route            | Method | Description                 |
|------------------|--------|-----------------------------|
| `/register`      | POST   | Register a new user         |
| `/login`         | POST   | Login an existing user      |
| `/verify`        | POST   | Verify user OTP             |

### File Routes (`/api/files`)

| Route            | Method | Description                    |
|------------------|--------|--------------------------------|
| `/upload`        | POST   | Upload a new file              |
| `/`              | GET    | Get all files for a user       |
| `/:id`           | GET    | Get a specific file by ID      |
| `/:id`           | PUT    | Update a file's details        |
| `/:id`           | DELETE | Delete a file from storage     |

## Inspiration

"To achieve something remarkable, we must go beyond what is comfortable and expected. **CDrive** isn't just another file management tool—it's a testament to the power of persistence, creativity, and belief in the process. Every feature, every bug fix, and every improvement is a step towards excellence."

As developers, we write more than just code. We write our stories of resilience, determination, and growth. Remember, the journey is as important as the destination.

Keep pushing boundaries, and keep creating something that truly matters.

## Author

Developed by **Chirag S Kotian**.

Feel free to reach out for any questions, feedback, or collaboration!

---