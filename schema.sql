-- Car Rental Database - Schema

DROP DATABASE IF EXISTS car_rental;
CREATE DATABASE car_rental;
USE car_rental;

CREATE TABLE Branch (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    name      VARCHAR(50) NOT NULL,
    city      VARCHAR(50) NOT NULL,
    address   VARCHAR(100),
    phone     VARCHAR(20)
);

CREATE TABLE Car_Model (
    model_id   INT AUTO_INCREMENT PRIMARY KEY,
    make       VARCHAR(30) NOT NULL,
    model      VARCHAR(30) NOT NULL,
    category   VARCHAR(20) NOT NULL,
    seats      INT NOT NULL,
    daily_rate DECIMAL(8,2) NOT NULL
);

CREATE TABLE Car (
    car_id     INT AUTO_INCREMENT PRIMARY KEY,
    reg_number VARCHAR(15) NOT NULL UNIQUE,
    model_id   INT NOT NULL,
    branch_id  INT NOT NULL,
    year       INT,
    mileage    INT,
    status     VARCHAR(20) DEFAULT 'available',
    FOREIGN KEY (model_id)  REFERENCES Car_Model(model_id),
    FOREIGN KEY (branch_id) REFERENCES Branch(branch_id)
);

CREATE TABLE Customer (
    customer_id   INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(40) NOT NULL,
    last_name     VARCHAR(40) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    licence_no    VARCHAR(20) NOT NULL UNIQUE,
    date_of_birth DATE
);

CREATE TABLE Rental (
    rental_id          INT AUTO_INCREMENT PRIMARY KEY,
    customer_id        INT NOT NULL,
    car_id             INT NOT NULL,
    pickup_branch_id   INT NOT NULL,
    return_branch_id   INT NOT NULL,
    start_date         DATE NOT NULL,
    end_date           DATE NOT NULL,
    actual_return_date DATE,
    total_cost         DECIMAL(10,2),
    status             VARCHAR(20) DEFAULT 'booked',
    FOREIGN KEY (customer_id)      REFERENCES Customer(customer_id),
    FOREIGN KEY (car_id)           REFERENCES Car(car_id),
    FOREIGN KEY (pickup_branch_id) REFERENCES Branch(branch_id),
    FOREIGN KEY (return_branch_id) REFERENCES Branch(branch_id)
);

CREATE TABLE Payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id  INT NOT NULL,
    amount     DECIMAL(10,2) NOT NULL,
    method     VARCHAR(20),
    paid_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rental_id) REFERENCES Rental(rental_id)
);