const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const db = require('./db.js');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware to parse JSON
app.use(express.json());
app.use(cors());

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
    console.log('login api called');
    
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

// Book Reservation route
app.post('/reservation/create', (req, res) => {
    const { user_id, slot_id, start_time, end_time, amount } = req.body;

    if (!user_id || !slot_id || !start_time || !end_time) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    db.getConnection((err, conn) => {
        if (err) return res.status(500).json({ error: 'DB connection failed' });

        conn.beginTransaction(err => {
            if (err) {
                conn.release();
                return res.status(500).json({ error: 'Transaction start failed' });
            }

            const reserveQuery = `
                INSERT INTO reservations (user_id, slot_id, start_time, end_time)
                VALUES (?, ?, ?, ?)
            `;

            conn.query(reserveQuery, [user_id, slot_id, start_time, end_time], (err, reserveResult) => {
                if (err) {
                    return conn.rollback(() => {
                        conn.release();
                        res.status(500).json({ error: 'Reservation insert failed' });
                    });
                }

                const reservationId = reserveResult.insertId;

                const paymentQuery = `
                    INSERT INTO payments (reservation_id, amount, payment_status, payment_time)
                    VALUES (?, ?, ?, NOW())
                `;

                conn.query(paymentQuery, [reservationId, amount || 0, 'completed'], (err, paymentResult) => {
                    if (err) {
                        return conn.rollback(() => {
                            conn.release();
                            res.status(500).json({ error: 'Payment insert failed' });
                        });
                    }

                    const checkQuery = `
                        INSERT INTO check_in_out (reservation_id, check_in_time, check_out_time)
                        VALUES (?, NULL, NULL)
                    `;

                    conn.query(checkQuery, [reservationId], (err) => {
                        if (err) {
                            return conn.rollback(() => {
                                conn.release();
                                res.status(500).json({ error: 'Check-in insert failed' });
                            });
                        }

                        const slotQuery = `
                            UPDATE parking_slots SET is_available = ? WHERE slot_id = ?
                        `;

                        conn.query(slotQuery, [false, slot_id], (err) => {
                            if (err) {
                                return conn.rollback(() => {
                                    conn.release();
                                    res.status(500).json({ error: 'Slot update failed' });
                                });
                            }

                            conn.commit(err => {
                                if (err) {
                                    return conn.rollback(() => {
                                        conn.release();
                                        res.status(500).json({ error: 'Commit failed' });
                                    });
                                }

                                conn.release();
                                res.json({
                                    message: 'Reservation and payment created successfully',
                                    reservation_id: reservationId,
                                    payment_id: paymentResult.insertId
                                });
                            });
                        });
                    });
                });
            });
        });
    });
});



// get fixed reservation route
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

// Submit Feedback route
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

// Get all feedback with user details
app.get('/feedback/all', (req, res) => {
    const query = `
        SELECT f.feedback_id, f.user_id, f.rating, f.comments as message, f.created_at, u.username
        FROM feedback f
        LEFT JOIN users u ON f.user_id = u.user_id
        ORDER BY f.created_at DESC
    `;
    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        res.json(results);
    });
});

// Delete feedback by ID
app.delete('/feedback/delete/:id', (req, res) => {
    const feedbackId = req.params.id;
    if (!feedbackId) {
        return res.status(400).json({ error: 'feedback_id is required' });
    }

    const query = 'DELETE FROM feedback WHERE feedback_id = ?';
    db.query(query, [feedbackId], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database delete failed' });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Feedback not found' });
        }
        res.json({ message: 'Feedback deleted successfully' });
    });
});

// Get User Profile route
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


// Create Parking Slot route
app.post('/slot/create', (req, res) => {
    const { slot_number, location, is_available, vehicle_type, price } = req.body;
    if (!slot_number || !location) {
        return res.status(400).json({ error: 'slot_number and location are required' });
    }

    console.log('Creating slot with:', { slot_number, location, is_available, vehicle_type, price });

    const finalPrice = price ? parseFloat(price) : 0;
    const query = 'INSERT INTO parking_slots (slot_number, location, is_available, vehicle_type, price) VALUES (?, ?, ?, ?, ?)';
    db.query(query, [slot_number, location, is_available || 1, vehicle_type || 'Car', finalPrice], (err, result) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ error: 'Database insert failed' });
        }
        res.json({ message: 'Parking slot created successfully', slot_id: result.insertId });
    });
});

// Delete Parking Slot route
app.delete('/slot/delete/:id', (req, res) => {
    const slotId = req.params.id;
    if (!slotId) {
        return res.status(400).json({ error: 'slot_id is required' });
    }

    const query = 'DELETE FROM parking_slots WHERE slot_id = ?';
    db.query(query, [slotId], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database delete failed' });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Parking slot not found' });
        }
        res.json({ message: 'Parking slot deleted successfully' });
    });
});

// Get all payments with user and reservation details
app.get('/payment/all', (req, res) => {
    const query = `
        SELECT p.payment_id, p.reservation_id, p.amount, p.payment_status, p.payment_time, u.username
        FROM payments p
        LEFT JOIN reservations r ON p.reservation_id = r.reservation_id
        LEFT JOIN users u ON r.user_id = u.user_id
        ORDER BY p.payment_time DESC
    `;
    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        res.json(results);
    });
});

// Update payment status
app.put('/payment/update/:id', (req, res) => {
    const paymentId = req.params.id;
    const { payment_status } = req.body;

    if (!paymentId || !payment_status) {
        return res.status(400).json({ error: 'payment_id and payment_status are required' });
    }

    const query = 'UPDATE payments SET payment_status = ? WHERE payment_id = ?';
    db.query(query, [payment_status, paymentId], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database update failed' });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Payment not found' });
        }
        res.json({ message: 'Payment status updated successfully' });
    });
});

// Delete payment
app.delete('/payment/delete/:id', (req, res) => {
    const paymentId = req.params.id;
    if (!paymentId) {
        return res.status(400).json({ error: 'payment_id is required' });
    }

    const query = 'DELETE FROM payments WHERE payment_id = ?';
    db.query(query, [paymentId], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database delete failed' });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Payment not found' });
        }
        res.json({ message: 'Payment deleted successfully' });
    });
});

// Get all check-in/check-out records with user and parking slot details
app.get('/checkinout/all', (req, res) => {
    const query = `
        SELECT c.check_id, c.reservation_id, c.check_in_time, c.check_out_time, 
               u.username, u.vehicle_number, ps.slot_number, ps.vehicle_type AS vehicle_type
        FROM check_in_out c
        LEFT JOIN reservations r ON c.reservation_id = r.reservation_id
        LEFT JOIN users u ON r.user_id = u.user_id
        LEFT JOIN parking_slots ps ON r.slot_id = ps.slot_id
        ORDER BY c.check_in_time DESC
    `;
    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        console.log(results);
        
        res.json(results);
    });
});

// Check-in a vehicle
app.put('/checkinout/checkin/:id', (req, res) => {
    const checkId = req.params.id;
    if (!checkId) {
        return res.status(400).json({ error: 'check_id is required' });
    }

    const query = 'UPDATE check_in_out SET check_in_time = NOW() WHERE check_id = ? AND check_in_time IS NULL';
    db.query(query, [checkId], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database update failed' });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Check record not found or already checked in' });
        }
        res.json({ message: 'Vehicle checked in successfully' });
    });
});

// Check-out a vehicle
app.put('/checkinout/checkout/:id', (req, res) => {
    const checkId = req.params.id;
    if (!checkId) {
        return res.status(400).json({ error: 'check_id is required' });
    }

    const query = 'UPDATE check_in_out SET check_out_time = NOW() WHERE check_id = ? AND check_out_time IS NULL';
    db.query(query, [checkId], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database update failed' });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Check record not found or already checked out' });
        }
        res.json({ message: 'Vehicle checked out successfully' });
    });
});

// Delete check-in/check-out record
app.delete('/checkinout/delete/:id', (req, res) => {
    const checkId = req.params.id;
    if (!checkId) {
        return res.status(400).json({ error: 'check_id is required' });
    }

    const query = 'DELETE FROM check_in_out WHERE check_id = ?';
    db.query(query, [checkId], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database delete failed' });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Check record not found' });
        }
        res.json({ message: 'Check-in/check-out record deleted successfully' });
    });
});

// Get user reservations with check-in/out status
app.get('/user/reservations/:email', (req, res) => {
    const userEmail = req.params.email;
    if (!userEmail) {
        return res.status(400).json({ error: 'email is required' });
    }

    const query = `
        SELECT r.reservation_id, r.start_time, r.end_time, ps.slot_number, ps.location,
               c.check_id, c.check_in_time, c.check_out_time, u.vehicle_number, ps.vehicle_type AS vehicle_type
        FROM reservations r
        LEFT JOIN parking_slots ps ON r.slot_id = ps.slot_id
        LEFT JOIN check_in_out c ON r.reservation_id = c.reservation_id
        LEFT JOIN users u ON r.user_id = u.user_id
        WHERE u.email = ?
        ORDER BY r.start_time DESC
    `;
    db.query(query, [userEmail], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        res.json(results);
    });
});

// ============ UNDEVELOPED FEATURES FEEDBACK ENDPOINTS ============

// Submit undeveloped feature feedback
app.post('/undeveloped-feedback/submit', (req, res) => {
    const { user_id, rating, comments } = req.body;
    if (!user_id || !rating || !comments) {
        return res.status(400).json({ error: 'user_id, rating, and comments are required' });
    }

    if (rating < 1 || rating > 5) {
        return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    const query = 'INSERT INTO Undeveloped_Feedback (user_id, rating, comments) VALUES (?, ?, ?)';
    db.query(query, [user_id, rating, comments], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database insert failed' });
        }
        res.json({ message: 'Feedback submitted successfully', feedback_id: result.insertId });
    });
});

// Get all undeveloped feedback (for admin)
app.get('/undeveloped-feedback/all', (req, res) => {
    const query = `
        SELECT uf.feedback_id, uf.user_id, uf.rating, uf.comments, 
               uf.created_at, uf.updated_at, u.username
        FROM Undeveloped_Feedback uf
        LEFT JOIN users u ON uf.user_id = u.user_id
        ORDER BY uf.created_at DESC
    `;
    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        res.json(results);
    });
});

// Get undeveloped feedback by user ID
app.get('/undeveloped-feedback/user/:id', (req, res) => {
    const userId = req.params.id;
    if (!userId) {
        return res.status(400).json({ error: 'user_id is required' });
    }

    const query = `
        SELECT uf.feedback_id, uf.user_id, uf.rating, uf.comments, 
               uf.created_at, uf.updated_at
        FROM Undeveloped_Feedback uf
        WHERE uf.user_id = ?
        ORDER BY uf.created_at DESC
    `;
    db.query(query, [userId], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        res.json(results);
    });
});

// Update undeveloped feedback (user can edit their own)
app.put('/undeveloped-feedback/update/:id', (req, res) => {
    const feedbackId = req.params.id;
    const { user_id, rating, comments } = req.body;

    if (!feedbackId || !user_id || !rating || !comments) {
        return res.status(400).json({ error: 'feedback_id, user_id, rating, and comments are required' });
    }

    if (rating < 1 || rating > 5) {
        return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    // Verify that the user owns this feedback
    const checkQuery = 'SELECT user_id FROM Undeveloped_Feedback WHERE feedback_id = ?';
    db.query(checkQuery, [feedbackId], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        if (results.length === 0) {
            return res.status(404).json({ error: 'Feedback not found' });
        }
        if (results[0].user_id !== user_id) {
            return res.status(403).json({ error: 'Unauthorized: You can only edit your own feedback' });
        }

        const updateQuery = 'UPDATE Undeveloped_Feedback SET rating = ?, comments = ? WHERE feedback_id = ?';
        db.query(updateQuery, [rating, comments, feedbackId], (err, result) => {
            if (err) {
                return res.status(500).json({ error: 'Database update failed' });
            }
            res.json({ message: 'Feedback updated successfully' });
        });
    });
});

// Delete undeveloped feedback (user can delete their own)
app.delete('/undeveloped-feedback/delete/:id', (req, res) => {
    const feedbackId = req.params.id;
    const { user_id } = req.body;

    if (!feedbackId || !user_id) {
        return res.status(400).json({ error: 'feedback_id and user_id are required' });
    }

    // Verify that the user owns this feedback
    const checkQuery = 'SELECT user_id FROM Undeveloped_Feedback WHERE feedback_id = ?';
    db.query(checkQuery, [feedbackId], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        if (results.length === 0) {
            return res.status(404).json({ error: 'Feedback not found' });
        }
        if (results[0].user_id !== user_id) {
            return res.status(403).json({ error: 'Unauthorized: You can only delete your own feedback' });
        }

        const deleteQuery = 'DELETE FROM Undeveloped_Feedback WHERE feedback_id = ?';
        db.query(deleteQuery, [feedbackId], (err, result) => {
            if (err) {
                return res.status(500).json({ error: 'Database delete failed' });
            }
            res.json({ message: 'Feedback deleted successfully' });
        });
    });
});

// Get feedback statistics
app.get('/undeveloped-feedback/stats/overview', (req, res) => {
    const query = `
        SELECT 
            COUNT(*) as total_feedback,
            AVG(rating) as average_rating,
            MAX(rating) as highest_rating,
            MIN(rating) as lowest_rating
        FROM Undeveloped_Feedback
    `;
    db.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query failed' });
        }
        res.json(results[0]);
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server is listening on port http://localhost:${PORT}`);
});