-- Create the database
CREATE DATABASE IF NOT EXISTS smart_parking_db;
USE smart_parking_db;

-- Create Users table
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(15),
    vehicle_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Parking_Slots table
CREATE TABLE Parking_Slots (
    slot_id INT PRIMARY KEY AUTO_INCREMENT,
    slot_number VARCHAR(10) NOT NULL UNIQUE,
    is_available BOOLEAN DEFAULT TRUE,
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Reservations table
CREATE TABLE Reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    slot_id INT,
    reservation_time DATETIME NOT NULL,
    status ENUM('pending', 'confirmed', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES Parking_Slots(slot_id) ON DELETE CASCADE
);

-- Create Check_In_Out table
CREATE TABLE Check_In_Out (
    check_id INT PRIMARY KEY AUTO_INCREMENT,
    reservation_id INT,
    check_in_time DATETIME,
    check_out_time DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reservation_id) REFERENCES Reservations(reservation_id) ON DELETE CASCADE
);

-- Create Payments table
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    reservation_id INT,
    amount DECIMAL(10, 2) NOT NULL,
    payment_status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    payment_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reservation_id) REFERENCES Reservations(reservation_id) ON DELETE CASCADE
);

-- Create Feedback table
CREATE TABLE Feedback (
    feedback_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Insert sample data for testing
INSERT INTO Users (username, email, password, phone, vehicle_number) VALUES
('john_doe', 'john@example.com', 'hashed_password_123', '1234567890', 'XYZ1234'),
('jane_smith', 'jane@example.com', 'hashed_password_456', '0987654321', 'XYZ1234');

INSERT INTO Parking_Slots (slot_number, is_available, location) VALUES
('A1', TRUE, 'First Floor'),
('A2', TRUE, 'First Floor'),
('B1', FALSE, 'Second Floor');

INSERT INTO Reservations (user_id, slot_id, reservation_time, status) VALUES
(1, 1, '2025-09-26 10:00:00', 'confirmed'),
(2, 2, '2025-09-26 12:00:00', 'pending');

INSERT INTO Check_In_Out (reservation_id, check_in_time, check_out_time) VALUES
(1, '2025-09-26 10:05:00', NULL);

INSERT INTO Payments (reservation_id, amount, payment_status) VALUES
(1, 15.00, 'completed');

INSERT INTO Feedback (user_id, rating, comments) VALUES
(1, 4, 'Great parking system, but needs more slots.'),
(2, 5, 'Very convenient and easy to use.');