-- Car Rental Database - Dummy Data
USE car_rental;

INSERT INTO Branch (name, city, address, phone) VALUES
('Dublin City',    'Dublin', '12 Dame Street',      '01 555 0101'),
('Dublin Airport', 'Dublin', 'Terminal 2',          '01 555 0102'),
('Cork',           'Cork',   '8 Patrick Street',    '021 555 0201');

INSERT INTO Car_Model (make, model, category, seats, daily_rate) VALUES
('Toyota',     'Corolla',  'Economy', 5,  45.00),
('Volkswagen', 'Golf',     'Compact', 5,  50.00),
('Volkswagen', 'Tiguan',   'SUV',     5,  75.00),
('BMW',        '5 Series', 'Luxury',  5, 120.00),
('Ford',       'Transit',  'Van',     9,  95.00);

INSERT INTO Car (reg_number, model_id, branch_id, year, mileage, status) VALUES
('231-D-1001', 1, 1, 2023, 18000, 'available'),
('231-D-1002', 2, 1, 2023, 22000, 'rented'),
('222-D-2003', 3, 2, 2022, 41000, 'available'),
('241-D-2004', 4, 2, 2024,  9000, 'available'),
('221-C-3005', 1, 3, 2022, 52000, 'available'),
('232-C-3006', 5, 3, 2023, 27000, 'rented'),
('231-C-3007', 2, 3, 2023, 31000, 'available'),
('212-D-1008', 1, 1, 2021, 78000, 'maintenance');

INSERT INTO Customer (first_name, last_name, email, phone, licence_no, date_of_birth) VALUES
('Aoife',   'Murphy', 'aoife.murphy@example.com',   '087 111 2201', 'IE-100234', '1995-04-12'),
('Conor',   'Byrne',  'conor.byrne@example.com',    '086 222 3302', 'IE-100587', '1988-11-03'),
('Siobhan', 'Kelly',  'siobhan.kelly@example.com',  '085 333 4403', 'IE-101122', '1999-07-21'),
('Darragh', 'Walsh',  'darragh.walsh@example.com',  '083 444 5504', 'IE-101876', '1992-02-28'),
('Niamh',   'Ryan',   'niamh.ryan@example.com',     '087 555 6605', 'IE-102345', '1985-09-15'),
('Cian',    'Doyle',  'cian.doyle@example.com',     '086 666 7706', 'IE-102999', '2000-01-30');

-- total_cost = number of days x daily_rate
INSERT INTO Rental (customer_id, car_id, pickup_branch_id, return_branch_id,
                    start_date, end_date, actual_return_date, total_cost, status) VALUES
(1, 1, 1, 1, '2026-03-02', '2026-03-06', '2026-03-06', 180.00, 'completed'),
(2, 3, 2, 3, '2026-04-10', '2026-04-17', '2026-04-17', 525.00, 'completed'),
(3, 4, 2, 2, '2026-05-01', '2026-05-04', '2026-05-04', 360.00, 'completed'),
(4, 6, 3, 3, '2026-06-12', '2026-06-17', '2026-06-17', 475.00, 'completed'),
(1, 5, 3, 1, '2026-07-20', '2026-07-27', '2026-07-27', 315.00, 'completed'),
(5, 7, 3, 3, '2026-09-03', '2026-09-06', '2026-09-06', 150.00, 'completed'),
(6, 3, 2, 2, '2026-10-10', '2026-10-12', NULL,         150.00, 'cancelled'),
(2, 2, 1, 1, '2026-11-20', '2026-11-27', NULL,         350.00, 'active'),
(3, 6, 3, 3, '2026-11-15', '2026-11-22', NULL,         665.00, 'active'),   -- overdue
(4, 1, 1, 1, '2026-12-18', '2026-12-23', NULL,         225.00, 'booked');

INSERT INTO Payment (rental_id, amount, method, paid_at) VALUES
(1,  180.00, 'card',          '2026-03-06 10:15:00'),
(2,  525.00, 'card',          '2026-04-17 16:30:00'),
(3,  360.00, 'card',          '2026-05-04 12:00:00'),
(4,  475.00, 'bank_transfer', '2026-06-17 11:00:00'),
(5,  315.00, 'cash',          '2026-07-27 17:10:00'),
(6,  150.00, 'card',          '2026-09-06 14:20:00'),
(8,  100.00, 'card',          '2026-11-20 09:00:00'),   -- deposit
(9,  150.00, 'card',          '2026-11-15 09:20:00'),   -- deposit
(10,  50.00, 'card',          '2026-11-23 18:00:00');   -- deposit