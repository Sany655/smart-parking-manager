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
    slot_number VARCHAR(10) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    location VARCHAR(100),
    vehicle_type ENUM('Bike', 'Car', 'MicroBus') NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Reservations table
CREATE TABLE Reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    slot_id INT,
    start_time DATETIME,
    end_time DATETIME,
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

-- Insert sample data for testing
INSERT INTO Users (username, email, password, phone, vehicle_number) VALUES
('asdf', 'asdf@gmail.com', 'asdfasdf', '1234567890', 'XYZ1234'),
('attendant', 'attendant@gmail.com', 'asdfasdf', '1234567890', 'XYZ1234'),
('admin', 'admin@gmail.com', 'asdfasdf', '0987654321', 'XYZ1234');
