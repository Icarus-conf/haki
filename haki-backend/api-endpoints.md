# Chat App - API Endpoints Reference

Base URL: `http://localhost:3000`

> [!NOTE]
> For mobile apps, replace `localhost` with your machine's IP address (e.g. `192.168.1.5`).

## Authentication

### Register

`POST /auth/register`

```bash
curl -X POST http://localhost:3000/auth/register \
-H "Content-Type: application/json" \
-d '{
  "username": "johndoe",
  "password": "mypassword"
}'
```

### Login

`POST /auth/login`

```bash
curl -X POST http://localhost:3000/auth/login \
-H "Content-Type: application/json" \
-d '{
  "username": "johndoe",
  "password": "mypassword"
}'
```

*Returns: `{ "access_token": "YOUR_JWT_TOKEN" }`*

---

## User Profile

*All endpoints below require `-H "Authorization: Bearer YOUR_JWT_TOKEN"`*

### Get My Profile

`GET /users/me`

```bash
curl -X GET http://localhost:3000/users/me \
-H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Get All Users

`GET /users`

```bash
curl -X GET http://localhost:3000/users \
-H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Update Profile Details

`PATCH /users/profile`

```bash
curl -X PATCH http://localhost:3000/users/profile \
-H "Authorization: Bearer YOUR_JWT_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "displayName": "John Doe",
  "bio": "Software Engineer & Coffee Lover",
  "publicKey": "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
}'
```

### Upload Avatar

`POST /users/avatar`

```bash
curl -X POST http://localhost:3000/users/avatar \
-H "Authorization: Bearer YOUR_JWT_TOKEN" \
-F "file=@/path/to/your/image.jpg"
```

---

## Media & Messages

### Upload Message Attachment

`POST /users/upload`

```bash
curl -X POST http://localhost:3000/users/upload \
-H "Authorization: Bearer YOUR_JWT_TOKEN" \
-F "file=@/path/to/your/image.png"
```

*Returns: `{ "attachmentUrl": "/uploads/messages/filename.png" }`*

---

## WebSocket Events (Socket.IO)

*URL: `ws://localhost:3000`*
*Auth: Send token in `auth: { token: "Bearer YOUR_JWT_TOKEN" }`*

### Emit: `message`

```json
// Global
{ "message": "Hello everyone!" }

// Private
{ "message": "Hey John!", "recipientId": 5 }

// With Attachment
{ "message": "", "attachmentUrl": "/uploads/messages/file.png", "recipientId": 5 }
```

### Emit: `typing`

```json
{ "isTyping": true, "recipientId": 5 }
```

### Emit: `get_history`

```json
// Global history
{ "recipientId": null }

// Private history with user 5
{ "recipientId": 5 }
```

### Listen: `message`, `history`, `online_users`, `user_typing`

Refer to `test-client.html` for payload structures.
