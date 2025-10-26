const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware to parse JSON
app.use(express.json());
app.use(cors());

// Create MySQL connection
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'smart_parking_db'
});

// Connect to MySQL
db.connect((err) => {
    if (err) {
        console.error('Error connecting to MySQL:', err);
        process.exit(1);
    }
    console.log('Connected to MySQL database');
});

// Basic route
app.get('/', (req, res) => {
    db.query('SELECT * FROM parking_slots', (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        res.json(results);
    });
});

// Login route
app.post('/auth/login', (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
        return res.status(400).json({ error: 'email and password are required' });
    }

    const query = 'SELECT * FROM users WHERE email = ? AND password = ?';
    db.query(query, [email, password], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        if (results.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        // For demonstration, just return user info (never return password in production)
        const user = results[0];
        delete user.password;
        
        res.json({ message: 'Login successful', user });
    });
});

// Registration route
app.post('/auth/register', (req, res) => {
    const { username, email, password, vehicle_number } = req.body;
    if (!username || !email || !password) {
        return res.status(400).json({ error: 'username, email, and password are required' });
    }

    // Check if email already exists
    const checkQuery = 'SELECT user_id FROM users WHERE email = ?';
    db.query(checkQuery, [email], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        if (results.length > 0) {
            return res.status(409).json({ error: 'Email already registered' });
        }

        // Insert new user
        const insertQuery = 'INSERT INTO users (username, email, password, vehicle_number) VALUES (?, ?, ?, ?)';
        db.query(insertQuery, [username, email, password, vehicle_number], (err, result) => {
            if (err) {
                return res.status(500).json({ error: 'Database insert failed' });
            }
            res.json({ message: 'Registration successful', user_id: result.insertId, status:200 });
        });
    });
});

app.post('/reservation/create', (req, res) => {
    const { user_id, slot_id, start_time, end_time } = req.body;
    if (!user_id || !slot_id || !start_time || !end_time) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const query = 'INSERT INTO reservations (user_id, slot_id, start_time, end_time) VALUES (?, ?, ?, ?)';
    db.query(query, [user_id, slot_id, start_time, end_time], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database insert failed' });
        }
        res.json({ message: 'Reservation created successfully', reservation_id: result.insertId });
    });
});

app.get('/reservation/:id', (req, res) => {
    const reservationId = req.params.id;
    const query = 'SELECT * FROM reservations WHERE id = ?';
    db.query(query, [reservationId], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        if (results.length === 0) {
            return res.status(404).json({ error: 'Reservation not found' });
        }
        res.json(results[0]);
    });
});

app.post('/feedback/submit', (req, res) => {
    const { user_id, message, rating } = req.body;
    if (!user_id || !message || typeof rating !== 'number') {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const query = 'INSERT INTO feedback (user_id, message, rating) VALUES (?, ?, ?)';
    db.query(query, [user_id, message, rating], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database insert failed' });
        }
        res.json({ message: 'Feedback submitted successfully', feedback_id: result.insertId });
    });
});

app.get('/user/profile/:id', (req, res) => {
    const userId = req.params.id;
    const query = 'SELECT id, username, email, created_at FROM users WHERE id = ?';
    db.query(query, [userId], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        if (results.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json(results[0]);
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server is listening on port http://localhost:${PORT}`);
});