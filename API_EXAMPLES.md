# API Examples - Feedback Endpoints

## Base URL
```
http://localhost:3000
```

## 1. Submit Feedback
Submit new feedback with rating and comments.

**Request:**
```
POST /undeveloped-feedback/submit
Content-Type: application/json

{
  "user_id": 1,
  "rating": 4,
  "comments": "Great app! The parking reservation feature works perfectly, but it would be nice to have monthly passes."
}
```

**Success Response (200):**
```json
{
  "message": "Feedback submitted successfully",
  "feedback_id": 15
}
```

**Error Response (400):**
```json
{
  "error": "rating, comments are required"
}
```

---

## 2. Get All Feedback (Admin)
Retrieve all feedback from all users.

**Request:**
```
GET /undeveloped-feedback/all
```

**Success Response (200):**
```json
[
  {
    "feedback_id": 1,
    "user_id": 5,
    "rating": 5,
    "comments": "Excellent parking system!",
    "created_at": "2024-11-18 09:30:00",
    "updated_at": "2024-11-18 09:30:00",
    "username": "john_doe"
  },
  {
    "feedback_id": 2,
    "user_id": 3,
    "rating": 3,
    "comments": "Good but needs improvement",
    "created_at": "2024-11-18 10:15:00",
    "updated_at": "2024-11-18 11:00:00",
    "username": "jane_smith"
  }
]
```

**Error Response (500):**
```json
{
  "error": "Database query failed"
}
```

---

## 3. Get User's Feedback
Get all feedback submitted by a specific user.

**Request:**
```
GET /undeveloped-feedback/user/5
```

**Success Response (200):**
```json
[
  {
    "feedback_id": 1,
    "user_id": 5,
    "rating": 5,
    "comments": "Excellent parking system!",
    "created_at": "2024-11-18 09:30:00",
    "updated_at": "2024-11-18 09:30:00"
  },
  {
    "feedback_id": 8,
    "user_id": 5,
    "rating": 4,
    "comments": "Updated feedback with new suggestions",
    "created_at": "2024-11-18 14:00:00",
    "updated_at": "2024-11-18 14:45:00"
  }
]
```

**Error Response (400):**
```json
{
  "error": "user_id is required"
}
```

---

## 4. Update Feedback
Edit an existing feedback (user can only update their own).

**Request:**
```
PUT /undeveloped-feedback/update/8
Content-Type: application/json

{
  "user_id": 5,
  "rating": 5,
  "comments": "Changed my mind, it's actually excellent! Love the new features."
}
```

**Success Response (200):**
```json
{
  "message": "Feedback updated successfully"
}
```

**Error Response (403):**
```json
{
  "error": "Unauthorized: You can only edit your own feedback"
}
```

**Error Response (400):**
```json
{
  "error": "Rating must be between 1 and 5"
}
```

---

## 5. Delete Feedback
Remove a feedback entry (user can only delete their own).

**Request:**
```
DELETE /undeveloped-feedback/delete/8
Content-Type: application/json

{
  "user_id": 5
}
```

**Success Response (200):**
```json
{
  "message": "Feedback deleted successfully"
}
```

**Error Response (403):**
```json
{
  "error": "Unauthorized: You can only delete your own feedback"
}
```

**Error Response (404):**
```json
{
  "error": "Feedback not found"
}
```

---

## 6. Get Feedback Statistics
Get overview statistics about all feedback.

**Request:**
```
GET /undeveloped-feedback/stats/overview
```

**Success Response (200):**
```json
{
  "total_feedback": 25,
  "average_rating": 4.12,
  "highest_rating": 5,
  "lowest_rating": 2
}
```

---

## Error Status Codes

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 400 | Bad Request (validation error) |
| 403 | Forbidden (authorization error) |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## Example: Complete User Feedback Workflow

### 1. User Submits Feedback
```bash
curl -X POST http://localhost:3000/undeveloped-feedback/submit \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 5,
    "rating": 4,
    "comments": "Great parking app! Could use some improvements."
  }'
```

### 2. User Fetches Their Feedback
```bash
curl http://localhost:3000/undeveloped-feedback/user/5
```

### 3. User Updates Their Feedback
```bash
curl -X PUT http://localhost:3000/undeveloped-feedback/update/15 \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 5,
    "rating": 5,
    "comments": "Actually, after using it more, it is excellent!"
  }'
```

### 4. Admin Views All Feedback
```bash
curl http://localhost:3000/undeveloped-feedback/all
```

### 5. Admin Deletes Inappropriate Feedback
```bash
curl -X DELETE http://localhost:3000/undeveloped-feedback/delete/15
```

---

## Validation Rules

### Rating
- Must be between 1 and 5
- Type: Integer
- Required: Yes

### Comments
- Minimum length: 5 characters
- Maximum length: 500 characters
- Type: String (Text)
- Required: Yes

### User ID
- Must be valid user_id from Users table
- Type: Integer
- Required: Yes

---

## Response Format

### Success Response
```json
{
  "message": "Operation successful",
  "feedback_id": 123,
  "data": {}
}
```

### Error Response
```json
{
  "error": "Description of what went wrong"
}
```

---

## CORS & Headers

All requests should include:
```
Content-Type: application/json
```

The backend is configured with CORS enabled, so requests from the Flutter frontend will be accepted.
