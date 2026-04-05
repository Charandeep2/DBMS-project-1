-- ======================================================
-- STEP 1: DATABASE INITIALIZATION
-- Task: Clean up and create separate spaces for Live Data and Analytics.
-- ======================================================
DROP DATABASE IF EXISTS road_accident_dw;
DROP DATABASE IF EXISTS road_accident_oltp;

CREATE DATABASE road_accident_oltp;
CREATE DATABASE road_accident_dw;

-- ======================================================
-- STEP 2: OLTP STRUCTURE (The "Live" System)
-- ======================================================
USE road_accident_oltp;

CREATE TABLE Driver (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_name VARCHAR(100),
    license_number VARCHAR(50) UNIQUE,
    phone VARCHAR(15),
    address VARCHAR(255)
);

CREATE TABLE Vehicle (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT,
    vehicle_number VARCHAR(20) UNIQUE,
    vehicle_type VARCHAR(50),
    model VARCHAR(100),
    FOREIGN KEY (driver_id) REFERENCES Driver(driver_id)
);

CREATE TABLE Location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    state VARCHAR(100),
    city VARCHAR(100),
    area VARCHAR(255),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6)
);

CREATE TABLE Weather (
    weather_id INT AUTO_INCREMENT PRIMARY KEY,
    weather_condition VARCHAR(50),
    temperature INT,
    humidity INT
);

CREATE TABLE Hospital (
    hospital_id INT AUTO_INCREMENT PRIMARY KEY,
    hospital_name VARCHAR(150),
    hospital_address VARCHAR(255),
    city VARCHAR(100)
);

CREATE TABLE Accident (
    accident_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT,
    location_id INT,
    weather_id INT,
    hospital_id INT,
    accident_date DATE,
    accident_time TIME,
    casualties INT,
    accident_status VARCHAR(50),
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id),
    FOREIGN KEY (location_id) REFERENCES Location(location_id),
    FOREIGN KEY (weather_id) REFERENCES Weather(weather_id),
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id)
);

CREATE TABLE Officer_Report (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    accident_id INT,
    officer_name VARCHAR(100),
    report_details TEXT,
    report_date DATE,
    FOREIGN KEY (accident_id) REFERENCES Accident(accident_id)
);

-- ======================================================
-- STEP 3: DATA WAREHOUSE STRUCTURE (The "Analytics" System)
-- ======================================================
USE road_accident_dw;

CREATE TABLE Dim_Time (
    time_id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE UNIQUE,
    day INT, month INT, year INT
);

CREATE TABLE Dim_Location (
    location_id INT PRIMARY KEY, 
    state VARCHAR(100), 
    city VARCHAR(100)
);

CREATE TABLE Dim_Vehicle (
    vehicle_id INT PRIMARY KEY, 
    vehicle_type VARCHAR(50)
);

CREATE TABLE Dim_Weather (
    weather_id INT PRIMARY KEY, 
    weather_condition VARCHAR(50)
);

CREATE TABLE Fact_Accident (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    accident_id INT,
    time_id INT,
    location_id INT,
    vehicle_id INT,
    weather_id INT,
    casualties INT,
    FOREIGN KEY (time_id) REFERENCES Dim_Time(time_id),
    FOREIGN KEY (location_id) REFERENCES Dim_Location(location_id),
    FOREIGN KEY (vehicle_id) REFERENCES Dim_Vehicle(vehicle_id),
    FOREIGN KEY (weather_id) REFERENCES Dim_Weather(weather_id)
);

-- ======================================================
-- STEP 4: THE MASTER TRIGGERS (Full Autonomous Sync)
-- Task: Keep ALL Data Warehouse tables perfectly synced with OLTP.
-- ======================================================
USE road_accident_oltp;
DELIMITER //

-- Trigger 1: Sync Vehicle to DW Dimension
CREATE TRIGGER sync_vehicle_to_dw AFTER INSERT ON Vehicle
FOR EACH ROW
BEGIN
    INSERT INTO road_accident_dw.Dim_Vehicle (vehicle_id, vehicle_type)
    VALUES (NEW.vehicle_id, NEW.vehicle_type);
END //

-- Trigger 2: Sync Location to DW Dimension
CREATE TRIGGER sync_location_to_dw AFTER INSERT ON Location
FOR EACH ROW
BEGIN
    INSERT INTO road_accident_dw.Dim_Location (location_id, state, city)
    VALUES (NEW.location_id, NEW.state, NEW.city);
END //

-- Trigger 3: Sync Weather to DW Dimension
CREATE TRIGGER sync_weather_to_dw AFTER INSERT ON Weather
FOR EACH ROW
BEGIN
    INSERT INTO road_accident_dw.Dim_Weather (weather_id, weather_condition)
    VALUES (NEW.weather_id, NEW.weather_condition);
END //

-- Trigger 4: Sync Accident to Time Dimension and Fact Table
CREATE TRIGGER sync_accident_to_dw AFTER INSERT ON Accident
FOR EACH ROW
BEGIN
    -- Automatically update Time Dimension in DW
    INSERT IGNORE INTO road_accident_dw.Dim_Time (date, day, month, year)
    VALUES (NEW.accident_date, DAY(NEW.accident_date), MONTH(NEW.accident_date), YEAR(NEW.accident_date));

    -- Automatically update Fact Table in DW
    INSERT INTO road_accident_dw.Fact_Accident (accident_id, time_id, location_id, vehicle_id, weather_id, casualties)
    SELECT NEW.accident_id, t.time_id, NEW.location_id, NEW.vehicle_id, NEW.weather_id, NEW.casualties
    FROM road_accident_dw.Dim_Time t WHERE t.date = NEW.accident_date;
END //

DELIMITER ;

-- ======================================================
-- STEP 5: SAFETYDRIVE MOCK DATA GENERATOR (20 CASES)
-- ======================================================
USE road_accident_oltp;

-- Disable constraints temporarily to inject data smoothly
SET FOREIGN_KEY_CHECKS = 0;

-- 1. DRIVER TABLE
INSERT INTO Driver (driver_id, driver_name, license_number, phone, address) VALUES 
(1, 'Rahul Sharma', 'KA0120230001', '9876543210', '12 MG Road, Bengaluru'),
(2, 'Priya Patel', 'MH0220210045', '8765432109', 'Andheri West, Mumbai'),
(3, 'Amit Singh', 'DL0420190088', '7654321098', 'Connaught Place, Delhi'),
(4, 'Sneha Reddy', 'TS0920220112', '9988776655', 'Banjara Hills, Hyderabad'),
(5, 'Vikram Kumar', 'TN0120200334', '9898989898', 'T Nagar, Chennai'),
(6, 'Neha Gupta', 'UP3220180445', '8787878787', 'Gomti Nagar, Lucknow'),
(7, 'Rohan Desai', 'GJ0120210556', '7676767676', 'Navrangpura, Ahmedabad'),
(8, 'Anjali Verma', 'WB0220190667', '9595959595', 'Salt Lake, Kolkata'),
(9, 'Karan Malhotra', 'PB0120230778', '8484848484', 'Sector 17, Chandigarh'),
(10, 'Pooja Joshi', 'RJ1420200889', '7373737373', 'Malviya Nagar, Jaipur'),
(11, 'Suresh Nair', 'KL0120220990', '9292929292', 'MG Road, Kochi'),
(12, 'Divya Singh', 'MP0420181101', '8181818181', 'Arera Colony, Bhopal'),
(13, 'Manoj Tiwari', 'BR0120211212', '9090909090', 'Boring Road, Patna'),
(14, 'Kavita Das', 'OD0220191323', '7979797979', 'Saheed Nagar, Bhubaneswar'),
(15, 'Arjun Rao', 'AP0920231434', '9876501234', 'MVP Colony, Visakhapatnam'),
(16, 'Riya Sen', 'AS0120201545', '8765409876', 'GS Road, Guwahati'),
(17, 'Gaurav Jain', 'CG0420221656', '7654308765', 'Civil Lines, Raipur'),
(18, 'Meera Rajput', 'UK0720181767', '9988007766', 'Rajpur Road, Dehradun'),
(19, 'Nitin Yadav', 'HR2620211878', '8877006655', 'DLF Phase 3, Gurugram'),
(20, 'Swati Mishra', 'JH0120191989', '7766005544', 'Kanke Road, Ranchi');

-- 2. VEHICLE TABLE
INSERT INTO Vehicle (vehicle_id, driver_id, vehicle_number, vehicle_type, model) VALUES 
(1, 1, 'KA-01-AB-1234', 'Car', 'Maruti Swift'),
(2, 2, 'MH-02-CD-5678', 'Bike', 'Honda Activa'),
(3, 3, 'DL-04-EF-9012', 'Car', 'Hyundai i20'),
(4, 4, 'TS-09-GH-3456', 'SUV', 'Toyota Fortuner'),
(5, 5, 'TN-01-IJ-7890', 'Truck', 'Tata Prima'),
(6, 6, 'UP-32-KL-1234', 'Car', 'Honda City'),
(7, 7, 'GJ-01-MN-5678', 'Bike', 'Royal Enfield Classic'),
(8, 8, 'WB-02-OP-9012', 'Car', 'Tata Nexon'),
(9, 9, 'PB-01-QR-3456', 'SUV', 'Mahindra Thar'),
(10, 10, 'RJ-14-ST-7890', 'Bus', 'Ashok Leyland Falcon'),
(11, 11, 'KL-01-UV-1234', 'Car', 'Kia Seltos'),
(12, 12, 'MP-04-WX-5678', 'Bike', 'Bajaj Pulsar'),
(13, 13, 'BR-01-YZ-9012', 'Car', 'Renault Kwid'),
(14, 14, 'OD-02-AB-3456', 'SUV', 'Hyundai Creta'),
(15, 15, 'AP-09-CD-7890', 'Truck', 'Eicher Pro'),
(16, 16, 'AS-01-EF-1234', 'Car', 'Maruti Baleno'),
(17, 17, 'CG-04-GH-5678', 'Bike', 'TVS Jupiter'),
(18, 18, 'UK-07-IJ-9012', 'Car', 'Volkswagen Polo'),
(19, 19, 'HR-26-KL-3456', 'SUV', 'Ford Endeavour'),
(20, 20, 'JH-01-MN-7890', 'Bus', 'Tata Starbus');

-- 3. LOCATION TABLE
INSERT INTO Location (location_id, state, city, area, latitude, longitude) VALUES 
(1, 'Karnataka', 'Bengaluru', 'Silk Board Junction', 12.9172, 77.6228),
(2, 'Maharashtra', 'Mumbai', 'Bandra Worli Sea Link', 19.0356, 72.8166),
(3, 'Delhi', 'New Delhi', 'India Gate Circle', 28.6129, 77.2295),
(4, 'Telangana', 'Hyderabad', 'Madhapur IT Park', 17.4483, 78.3915),
(5, 'Tamil Nadu', 'Chennai', 'Marina Beach Road', 13.0500, 80.2824),
(6, 'Uttar Pradesh', 'Lucknow', 'Hazratganj Crossing', 26.8467, 80.9462),
(7, 'Gujarat', 'Ahmedabad', 'SG Highway', 23.0225, 72.5714),
(8, 'West Bengal', 'Kolkata', 'Howrah Bridge', 22.5851, 88.3468),
(9, 'Punjab', 'Chandigarh', 'Tribune Chowk', 30.7333, 76.7794),
(10, 'Rajasthan', 'Jaipur', 'Ajmeri Gate', 26.9124, 75.7873),
(11, 'Kerala', 'Kochi', 'Edappally Toll', 9.9312, 76.2673),
(12, 'Madhya Pradesh', 'Bhopal', 'VIP Road', 23.2599, 77.4126),
(13, 'Bihar', 'Patna', 'Gandhi Maidan', 25.5941, 85.1376),
(14, 'Odisha', 'Bhubaneswar', 'Khandagiri Square', 20.2961, 85.8245),
(15, 'Andhra Pradesh', 'Visakhapatnam', 'RK Beach Road', 17.6868, 83.2185),
(16, 'Assam', 'Guwahati', 'Paltan Bazaar', 26.1445, 91.7362),
(17, 'Chhattisgarh', 'Raipur', 'Jai Stambh Chowk', 21.2514, 81.6296),
(18, 'Uttarakhand', 'Dehradun', 'Clock Tower', 30.3165, 78.0322),
(19, 'Haryana', 'Gurugram', 'Cyber City', 28.4595, 77.0266),
(20, 'Jharkhand', 'Ranchi', 'Albert Ekka Chowk', 23.3441, 85.3096);

-- 4. WEATHER TABLE
INSERT INTO Weather (weather_id, weather_condition, temperature, humidity) VALUES 
(1, 'Rainy', 24, 85),
(2, 'Clear', 32, 60),
(3, 'Foggy', 15, 90),
(4, 'Overcast', 28, 75),
(5, 'Rainy', 26, 88),
(6, 'Clear', 35, 50),
(7, 'Clear', 38, 45),
(8, 'Foggy', 18, 92),
(9, 'Overcast', 22, 70),
(10, 'Clear', 40, 30),
(11, 'Rainy', 27, 85),
(12, 'Clear', 33, 55),
(13, 'Overcast', 30, 65),
(14, 'Rainy', 29, 80),
(15, 'Clear', 31, 75),
(16, 'Foggy', 20, 88),
(17, 'Clear', 34, 50),
(18, 'Overcast', 25, 60),
(19, 'Foggy', 12, 95),
(20, 'Clear', 28, 55);

-- 5. HOSPITAL TABLE
INSERT INTO Hospital (hospital_id, hospital_name, hospital_address, city) VALUES 
(1, 'Apollo Hospitals', 'Bannerghatta Road', 'Bengaluru'),
(2, 'Lilavati Hospital', 'Bandra Reclamation', 'Mumbai'),
(3, 'AIIMS', 'Ansari Nagar', 'New Delhi'),
(4, 'Yashoda Hospitals', 'Somajiguda', 'Hyderabad'),
(5, 'Christian Medical College', 'Ida Scudder Road', 'Vellore'),
(6, 'Sanjay Gandhi PGIMS', 'Raebareli Road', 'Lucknow'),
(7, 'Civil Hospital', 'Asarwa', 'Ahmedabad'),
(8, 'AMRI Hospitals', 'Dhakuria', 'Kolkata'),
(9, 'PGIMER', 'Sector 12', 'Chandigarh'),
(10, 'SMS Hospital', 'JLN Marg', 'Jaipur'),
(11, 'Amrita Hospital', 'Edappally', 'Kochi'),
(12, 'Bansal Hospital', 'Shahpura', 'Bhopal'),
(13, 'PMCH', 'Ashok Rajpath', 'Patna'),
(14, 'Kalinga Hospital', 'Chandrasekharpur', 'Bhubaneswar'),
(15, 'Care Hospitals', 'Ram Nagar', 'Visakhapatnam'),
(16, 'Gauhati Medical College', 'Bhangagarh', 'Guwahati'),
(17, 'Ramkrishna Care', 'Aurobindo Enclave', 'Raipur'),
(18, 'Max Super Speciality', 'Malsi', 'Dehradun'),
(19, 'Medanta', 'Sector 38', 'Gurugram'),
(20, 'RIMS', 'Bariatu', 'Ranchi');

-- 6. ACCIDENT TABLE
INSERT INTO Accident (accident_id, vehicle_id, location_id, weather_id, hospital_id, accident_date, accident_time, casualties, accident_status) VALUES 
(1, 1, 1, 1, 1, '2023-10-15', '08:30:00', 0, 'Closed'),
(2, 2, 2, 2, 2, '2023-10-16', '14:45:00', 1, 'Closed'),
(3, 3, 3, 3, 3, '2023-11-02', '06:15:00', 2, 'Under Investigation'),
(4, 4, 4, 4, 4, '2023-11-10', '18:20:00', 0, 'Closed'),
(5, 5, 5, 5, 5, '2023-11-25', '23:10:00', 3, 'Active'),
(6, 6, 6, 6, 6, '2023-12-05', '09:00:00', 1, 'Closed'),
(7, 7, 7, 7, 7, '2023-12-12', '12:30:00', 0, 'Closed'),
(8, 8, 8, 8, 8, '2023-12-20', '07:45:00', 2, 'Under Investigation'),
(9, 9, 9, 9, 9, '2024-01-08', '16:00:00', 1, 'Closed'),
(10, 10, 10, 10, 10, '2024-01-15', '10:15:00', 5, 'Active'),
(11, 11, 11, 11, 11, '2024-01-22', '13:40:00', 0, 'Closed'),
(12, 12, 12, 12, 12, '2024-02-05', '19:55:00', 1, 'Under Investigation'),
(13, 13, 13, 13, 13, '2024-02-14', '08:25:00', 0, 'Closed'),
(14, 14, 14, 14, 14, '2024-02-28', '21:30:00', 2, 'Active'),
(15, 15, 15, 15, 15, '2024-03-10', '11:10:00', 1, 'Closed'),
(16, 16, 16, 16, 16, '2024-03-18', '05:50:00', 0, 'Closed'),
(17, 17, 17, 17, 17, '2024-04-02', '15:20:00', 1, 'Under Investigation'),
(18, 18, 18, 18, 18, '2024-04-12', '07:05:00', 2, 'Active'),
(19, 19, 19, 19, 19, '2024-04-20', '22:45:00', 0, 'Closed'),
(20, 20, 20, 20, 20, '2024-05-01', '14:15:00', 3, 'Active');

-- 7. OFFICER REPORT TABLE
INSERT INTO Officer_Report (report_id, accident_id, officer_name, report_details, report_date) VALUES 
(1, 1, 'Inspector R.K. Narayan', 'Minor rear-end collision due to slippery roads. No injuries.', '2023-10-16'),
(2, 2, 'Sub-Inspector S.K. Patil', 'Bike skidded on an oil spill. Rider sustained minor bruises.', '2023-10-17'),
(3, 3, 'Inspector A.K. Sharma', 'Low visibility caused a multi-car pileup. Investigation ongoing.', '2023-11-03'),
(4, 4, 'Sub-Inspector M.N. Reddy', 'Vehicle hit a divider to avoid a stray animal. Damage to front bumper.', '2023-11-11'),
(5, 5, 'Inspector V.S. Iyer', 'Truck lost control and overturned. Multiple casualties reported.', '2023-11-26'),
(6, 6, 'Sub-Inspector P.K. Yadav', 'Speeding car crashed into a parked vehicle. Driver fined.', '2023-12-06'),
(7, 7, 'Inspector D.C. Patel', 'Minor scraping incident in heavy traffic. Both parties settled.', '2023-12-13'),
(8, 8, 'Sub-Inspector S.R. Das', 'Fog caused misjudgment of distance. Two injured in the crash.', '2023-12-21'),
(9, 9, 'Inspector H.S. Gill', 'Tire burst caused the SUV to swerve. Occupants safe.', '2024-01-09'),
(10, 10, 'Sub-Inspector T.R. Meena', 'Bus collided with a commercial truck. Major rescue operation conducted.', '2024-01-16'),
(11, 11, 'Inspector K.M. Pillai', 'Hydroplaning due to heavy rain. Vehicle hit a guardrail.', '2024-01-23'),
(12, 12, 'Sub-Inspector R.P. Chouhan', 'Bike hit a pothole. Rider hospitalized for observation.', '2024-02-06'),
(13, 13, 'Inspector N.K. Singh', 'Distracted driving led to a minor fender bender.', '2024-02-15'),
(14, 14, 'Sub-Inspector B.C. Mohanty', 'SUV rolled over after taking a sharp turn at high speed.', '2024-02-29'),
(15, 15, 'Inspector G.V. Rao', 'Truck brakes failed on a slope. Driver managed to stop safely.', '2024-03-11'),
(16, 16, 'Sub-Inspector A.B. Baruah', 'Car stalled in waterlogged street. Towed away.', '2024-03-19'),
(17, 17, 'Inspector C.S. Verma', 'Two-wheeler collision at an intersection. Traffic light malfunction.', '2024-04-03'),
(18, 18, 'Sub-Inspector M.K. Rawat', 'Car hit a tree in dense fog. Occupants severely injured.', '2024-04-13'),
(19, 19, 'Inspector R.S. Hooda', 'Multi-vehicle collision due to sudden braking. No injuries.', '2024-04-21'),
(20, 20, 'Sub-Inspector S.N. Munda', 'Bus crashed into a shop. Driver apprehended.', '2024-05-02');

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;


-- ========================================================
-- SAFETYDRIVE MOCK DATA: BATCH 2 (CASES 21 TO 50)
-- ========================================================

-- Disable foreign key checks temporarily for bulk insertion
SET FOREIGN_KEY_CHECKS = 0;
USE road_accident_oltp;

-- 1. DRIVER TABLE (IDs 21 to 50)
INSERT INTO Driver (driver_id, driver_name, license_number, phone, address) VALUES 
(21, 'Vivek Menon', 'KL0720192233', '9876511223', 'MG Road, Ernakulam'),
(22, 'Shreya Ghoshal', 'WB0420213344', '8765422334', 'Park Street, Kolkata'),
(23, 'Manish Pandey', 'UP1420184455', '7654333445', 'Raj Nagar, Ghaziabad'),
(24, 'Kavya Shetty', 'KA0320225566', '9988744556', 'Indiranagar, Bengaluru'),
(25, 'Rajat Tokas', 'MP0920206677', '9898955667', 'Vijay Nagar, Indore'),
(26, 'Anita Dongre', 'MH1220197788', '8787866778', 'Koregaon Park, Pune'),
(27, 'Harish Kalyan', 'TS0720238899', '7676777889', 'Secunderabad, Telangana'),
(28, 'Priya Prakash', 'TN0220219900', '9595988990', 'Anna Nagar, Chennai'),
(29, 'Gopal Varma', 'GJ0520181122', '8484899001', 'Adajan, Surat'),
(30, 'Simran Kaur', 'PB0220222233', '7373700112', 'Model Town, Amritsar'),
(31, 'Amitabh Roy', 'BR0620203344', '9292911223', 'Kankarbagh, Patna'),
(32, 'Deepika Das', 'OD0220194455', '8181822334', 'Patia, Bhubaneswar'),
(33, 'Naveen Kumar', 'AP1620235566', '9090933445', 'Benz Circle, Vijayawada'),
(34, 'Tanvi Sharma', 'RJ1420216677', '7979744556', 'Vaishali Nagar, Jaipur'),
(35, 'Raghav Juyal', 'DL0320187788', '9876555667', 'Vasant Kunj, Delhi'),
(36, 'Meenakshi Dixit', 'HR2620228899', '8765466778', 'Sector 56, Gurugram'),
(37, 'Sanjay Dutt', 'CG0420209900', '7654377889', 'Shankar Nagar, Raipur'),
(38, 'Pooja Hegde', 'KA1920191111', '9988088990', 'Kadri, Mangaluru'),
(39, 'Karthik Aryan', 'MH0220232222', '8877099001', 'Juhu, Mumbai'),
(40, 'Alia Bhatt', 'KA0120213333', '7766000112', 'Koramangala, Bengaluru'),
(41, 'Varun Dhawan', 'UP3220184444', '9876511111', 'Gomti Nagar, Lucknow'),
(42, 'Shraddha Kapoor', 'DL0120225555', '8765422222', 'Defence Colony, Delhi'),
(43, 'Tiger Shroff', 'MH0120206666', '7654333333', 'Colaba, Mumbai'),
(44, 'Kriti Sanon', 'TS0920197777', '9988744444', 'Jubilee Hills, Hyderabad'),
(45, 'Sidharth Malhotra', 'TN0120238888', '9898955555', 'Adyar, Chennai'),
(46, 'Disha Patani', 'GJ0120219999', '8787866666', 'Vastrapur, Ahmedabad'),
(47, 'Ayushmann Khurrana', 'PB0120180000', '7676777777', 'Sector 17, Chandigarh'),
(48, 'Kiara Advani', 'RJ1420221234', '9595988888', 'Malviya Nagar, Jaipur'),
(49, 'Vicky Kaushal', 'WB0220202345', '8484899999', 'Salt Lake, Kolkata'),
(50, 'Tara Sutaria', 'KL0120193456', '7373700000', 'Marine Drive, Kochi');

-- 2. VEHICLE TABLE (IDs 21 to 50)
INSERT INTO Vehicle (vehicle_id, driver_id, vehicle_number, vehicle_type, model) VALUES 
(21, 21, 'KL-07-AB-1111', 'Car', 'Maruti Alto'),
(22, 22, 'WB-04-CD-2222', 'SUV', 'Hyundai Creta'),
(23, 23, 'UP-14-EF-3333', 'Bike', 'TVS Apache'),
(24, 24, 'KA-03-GH-4444', 'Car', 'Honda City'),
(25, 25, 'MP-09-IJ-5555', 'Truck', 'Tata Signa'),
(26, 26, 'MH-12-KL-6666', 'Car', 'Skoda Seltos'),
(27, 27, 'TS-07-MN-7777', 'Bike', 'Royal Enfield'),
(28, 28, 'TN-02-OP-8888', 'SUV', 'Mahindra XUV700'),
(29, 29, 'GJ-05-QR-9999', 'Car', 'Hyundai i20'),
(30, 30, 'PB-02-ST-0000', 'Bus', 'Volvo B11R'),
(31, 31, 'BR-06-UV-1212', 'Bike', 'Hero Splendor'),
(32, 32, 'OD-02-WX-2323', 'Car', 'Tata Tiago'),
(33, 33, 'AP-16-YZ-3434', 'Truck', 'Eicher Pro'),
(34, 34, 'RJ-14-AB-4545', 'SUV', 'Toyota Fortuner'),
(35, 35, 'DL-03-CD-5656', 'Car', 'Maruti Swift'),
(36, 36, 'HR-26-EF-6767', 'Bike', 'Bajaj Dominar'),
(37, 37, 'CG-04-GH-7878', 'Car', 'Renault Kiger'),
(38, 38, 'KA-19-IJ-8989', 'Bus', 'Tata Starbus'),
(39, 39, 'MH-02-KL-9090', 'SUV', 'Kia Sonet'),
(40, 40, 'KA-01-MN-0101', 'Car', 'Honda Amaze'),
(41, 41, 'UP-32-OP-1212', 'Bike', 'KTM Duke'),
(42, 42, 'DL-01-QR-2323', 'Car', 'Volkswagen Polo'),
(43, 43, 'MH-01-ST-3434', 'SUV', 'MG Seltos'),
(44, 44, 'TS-09-UV-4545', 'Car', 'Hyundai Verna'),
(45, 45, 'TN-01-WX-5656', 'Bike', 'Yamaha R15'),
(46, 46, 'GJ-01-YZ-6767', 'Truck', 'Ashok Leyland'),
(47, 47, 'PB-01-AB-7878', 'Car', 'Maruti Baleno'),
(48, 48, 'RJ-14-CD-8989', 'SUV', 'Tata Safari'),
(49, 49, 'WB-02-EF-9090', 'Car', 'Honda Jazz'),
(50, 50, 'KL-01-GH-0101', 'Bike', 'Suzuki FZ');

-- 3. LOCATION TABLE (IDs 21 to 50)
INSERT INTO Location (location_id, state, city, area) VALUES 
(21, 'Kerala', 'Kochi', 'Vyttila Junction'),
(22, 'West Bengal', 'Kolkata', 'Bypass Road'),
(23, 'Uttar Pradesh', 'Ghaziabad', 'NH-24'),
(24, 'Karnataka', 'Bengaluru', 'KR Puram'),
(25, 'Madhya Pradesh', 'Indore', 'Super Corridor'),
(26, 'Maharashtra', 'Pune', 'Hinjewadi Phase 1'),
(27, 'Telangana', 'Hyderabad', 'Gachibowli Outer Ring Road'),
(28, 'Tamil Nadu', 'Chennai', 'OMR Toll Plaza'),
(29, 'Gujarat', 'Surat', 'Dumas Road'),
(30, 'Punjab', 'Amritsar', 'GT Road'),
(31, 'Bihar', 'Patna', 'Frazer Road'),
(32, 'Odisha', 'Bhubaneswar', 'Jaydev Vihar'),
(33, 'Andhra Pradesh', 'Vijayawada', 'Eluru Road'),
(34, 'Rajasthan', 'Jaipur', 'Tonk Road'),
(35, 'Delhi', 'New Delhi', 'Outer Ring Road'),
(36, 'Haryana', 'Gurugram', 'Golf Course Road'),
(37, 'Chhattisgarh', 'Raipur', 'GE Road'),
(38, 'Karnataka', 'Mangaluru', 'Pumpwell Circle'),
(39, 'Maharashtra', 'Mumbai', 'Western Express Highway'),
(40, 'Karnataka', 'Bengaluru', 'Hebbal Flyover'),
(41, 'Uttar Pradesh', 'Lucknow', 'Shaheed Path'),
(42, 'Delhi', 'New Delhi', 'DND Flyway'),
(43, 'Maharashtra', 'Mumbai', 'Eastern Freeway'),
(44, 'Telangana', 'Hyderabad', 'Banjara Hills Road No 12'),
(45, 'Tamil Nadu', 'Chennai', 'Mount Road'),
(46, 'Gujarat', 'Ahmedabad', 'Ashram Road'),
(47, 'Punjab', 'Chandigarh', 'Madhya Marg'),
(48, 'Rajasthan', 'Jaipur', 'JLN Marg'),
(49, 'West Bengal', 'Kolkata', 'EM Bypass'),
(50, 'Kerala', 'Kochi', 'Palarivattom');

-- 4. WEATHER TABLE (IDs 21 to 50)
INSERT INTO Weather (weather_id, weather_condition, temperature, humidity) VALUES 
(21, 'Rainy', 25, 90), (22, 'Overcast', 28, 75), (23, 'Foggy', 14, 95),
(24, 'Clear', 30, 50), (25, 'Clear', 35, 40), (26, 'Rainy', 22, 85),
(27, 'Clear', 33, 45), (28, 'Overcast', 31, 65), (29, 'Clear', 36, 55),
(30, 'Foggy', 12, 88), (31, 'Rainy', 26, 80), (32, 'Overcast', 29, 70),
(33, 'Clear', 34, 60), (34, 'Clear', 38, 30), (35, 'Foggy', 16, 92),
(36, 'Clear', 32, 45), (37, 'Rainy', 24, 85), (38, 'Rainy', 23, 90),
(39, 'Overcast', 28, 75), (40, 'Clear', 29, 50), (41, 'Foggy', 15, 95),
(42, 'Clear', 31, 40), (43, 'Rainy', 27, 88), (44, 'Clear', 35, 35),
(45, 'Overcast', 30, 65), (46, 'Clear', 37, 45), (47, 'Foggy', 13, 85),
(48, 'Clear', 39, 25), (49, 'Rainy', 25, 80), (50, 'Overcast', 28, 70);

-- 5. HOSPITAL TABLE (IDs 21 to 50)
INSERT INTO Hospital (hospital_id, hospital_name, hospital_address, city) VALUES 
(21, 'Lisie Hospital', 'Vyttila', 'Kochi'),
(22, 'Fortis Hospital', 'Anandapur', 'Kolkata'),
(23, 'Columbia Asia', 'NH-24', 'Ghaziabad'),
(24, 'Manipal Hospital', 'Old Airport Road', 'Bengaluru'),
(25, 'CHL Hospital', 'AB Road', 'Indore'),
(26, 'Ruby Hall Clinic', 'Dhole Patil Road', 'Pune'),
(27, 'AIG Hospitals', 'Gachibowli', 'Hyderabad'),
(28, 'Kauvery Hospital', 'Thoraipakkam', 'Chennai'),
(29, 'Sunshine Global', 'Piplod', 'Surat'),
(30, 'Amandeep Hospital', 'Model Town', 'Amritsar'),
(31, 'Paras Hospital', 'Bailey Road', 'Patna'),
(32, 'SUM Hospital', 'Khandagiri', 'Bhubaneswar'),
(33, 'Ramesh Hospitals', 'MG Road', 'Vijayawada'),
(34, 'Narayana Multispeciality', 'Pratap Nagar', 'Jaipur'),
(35, 'Fortis Escorts', 'Vasant Kunj', 'New Delhi'),
(36, 'Artemis Hospital', 'Sector 51', 'Gurugram'),
(37, 'MMI Narayana', 'Pachpedi Naka', 'Raipur'),
(38, 'KMC Hospital', 'Ambedkar Circle', 'Mangaluru'),
(39, 'Nanavati Hospital', 'Vile Parle', 'Mumbai'),
(40, 'Aster CMI', 'Hebbal', 'Bengaluru'),
(41, 'Sahara Hospital', 'Gomti Nagar', 'Lucknow'),
(42, 'Max Hospital', 'Saket', 'New Delhi'),
(43, 'Breach Candy', 'Bhulabhai Desai Road', 'Mumbai'),
(44, 'Apollo Health City', 'Jubilee Hills', 'Hyderabad'),
(45, 'Fortis Malar', 'Adyar', 'Chennai'),
(46, 'Zydus Hospital', 'SG Highway', 'Ahmedabad'),
(47, 'Fortis Hospital', 'Sector 62', 'Chandigarh'),
(48, 'EHCC Hospital', 'Malviya Nagar', 'Jaipur'),
(49, 'Peerless Hospital', 'Panchasayar', 'Kolkata'),
(50, 'Medical Trust', 'Kaloor', 'Kochi');

-- 6. ACCIDENT TABLE (IDs 21 to 50)
INSERT INTO Accident (accident_id, vehicle_id, location_id, weather_id, hospital_id, accident_date, accident_time, casualties, accident_status) VALUES 
(21, 21, 21, 21, 21, '2023-05-10', '09:15:00', 0, 'Closed'),
(22, 22, 22, 22, 22, '2023-05-15', '14:30:00', 2, 'Closed'),
(23, 23, 23, 23, 23, '2023-06-02', '07:45:00', 1, 'Closed'),
(24, 24, 24, 24, 24, '2023-06-20', '18:10:00', 0, 'Closed'),
(25, 25, 25, 25, 25, '2023-07-05', '23:45:00', 3, 'Closed'),
(26, 26, 26, 26, 26, '2023-07-18', '08:20:00', 1, 'Closed'),
(27, 27, 27, 27, 27, '2023-08-12', '13:00:00', 0, 'Closed'),
(28, 28, 28, 28, 28, '2023-08-25', '19:30:00', 2, 'Closed'),
(29, 29, 29, 29, 29, '2023-09-08', '11:15:00', 1, 'Closed'),
(30, 30, 30, 30, 30, '2023-09-22', '06:40:00', 4, 'Closed'),
(31, 31, 31, 31, 31, '2023-10-05', '15:50:00', 0, 'Closed'),
(32, 32, 32, 32, 32, '2023-10-18', '21:10:00', 2, 'Closed'),
(33, 33, 33, 33, 33, '2023-11-04', '10:25:00', 1, 'Closed'),
(34, 34, 34, 34, 34, '2023-11-20', '16:45:00', 0, 'Closed'),
(35, 35, 35, 35, 35, '2023-12-10', '07:15:00', 1, 'Closed'),
(36, 36, 36, 36, 36, '2024-01-05', '12:30:00', 0, 'Closed'),
(37, 37, 37, 37, 37, '2024-01-18', '18:50:00', 2, 'Closed'),
(38, 38, 38, 38, 38, '2024-02-02', '08:40:00', 1, 'Closed'),
(39, 39, 39, 39, 39, '2024-02-15', '14:15:00', 0, 'Closed'),
(40, 40, 40, 40, 40, '2024-03-01', '22:30:00', 3, 'Closed'),
(41, 41, 41, 41, 41, '2024-05-10', '09:00:00', 1, 'Under Investigation'),
(42, 42, 42, 42, 42, '2024-05-15', '13:45:00', 0, 'Active'),
(43, 43, 43, 43, 43, '2024-05-22', '19:10:00', 2, 'Active'),
(44, 44, 44, 44, 44, '2024-06-05', '08:30:00', 1, 'Under Investigation'),
(45, 45, 45, 45, 45, '2024-06-12', '15:20:00', 0, 'Active'),
(46, 46, 46, 46, 46, '2024-06-20', '21:05:00', 3, 'Active'),
(47, 47, 47, 47, 47, '2024-07-02', '07:45:00', 1, 'Under Investigation'),
(48, 48, 48, 48, 48, '2024-07-15', '12:15:00', 0, 'Active'),
(49, 49, 49, 49, 49, '2024-07-28', '18:40:00', 2, 'Active'),
(50, 50, 50, 50, 50, '2024-08-10', '10:30:00', 1, 'Under Investigation');

-- 7. OFFICER REPORT TABLE (IDs 21 to 50)
INSERT INTO Officer_Report (report_id, accident_id, officer_name, report_details, report_date) VALUES 
(21, 21, 'Insp. Rajesh', 'Skidded on wet road. No major damage.', '2023-05-11'),
(22, 22, 'Sub-Insp. Kumar', 'Collision at intersection. Two injured.', '2023-05-16'),
(23, 23, 'Insp. Singh', 'Bike hit pothole in fog. Minor injuries.', '2023-06-03'),
(24, 24, 'Sub-Insp. Ali', 'Rear end collision in traffic. Settled.', '2023-06-21'),
(25, 25, 'Insp. Sharma', 'Truck lost control on highway. Multiple casualties.', '2023-07-06'),
(26, 26, 'Sub-Insp. Patel', 'Car hit divider in rain. Driver injured.', '2023-07-19'),
(27, 27, 'Insp. Reddy', 'Minor scraping incident. No injuries.', '2023-08-13'),
(28, 28, 'Sub-Insp. Nair', 'SUV rolled over. Two occupants injured.', '2023-08-26'),
(29, 29, 'Insp. Desai', 'Hit and run. Investigating CCTV footage.', '2023-09-09'),
(30, 30, 'Sub-Insp. Gill', 'Bus collided with truck in fog. Severe crash.', '2023-09-23'),
(31, 31, 'Insp. Yadav', 'Bike skidded in rain. Rider safe.', '2023-10-06'),
(32, 32, 'Sub-Insp. Das', 'Head-on collision on single lane road.', '2023-10-19'),
(33, 33, 'Insp. Rao', 'Car hit stray animal. Minor injuries.', '2023-11-05'),
(34, 34, 'Sub-Insp. Jain', 'Fender bender at signal. No injuries.', '2023-11-21'),
(35, 35, 'Insp. Verma', 'Fog caused misjudgment. One injured.', '2023-12-11'),
(36, 36, 'Sub-Insp. Kapoor', 'Speeding car hit parked vehicle. Fined.', '2024-01-06'),
(37, 37, 'Insp. Khan', 'Multi-car pileup in rain. Two injured.', '2024-01-19'),
(38, 38, 'Sub-Insp. Bose', 'Bus hit divider. Passengers safe.', '2024-02-03'),
(39, 39, 'Insp. Joshi', 'Minor collision in traffic jam.', '2024-02-16'),
(40, 40, 'Sub-Insp. Mehta', 'Car overturned at high speed. Three injured.', '2024-03-02'),
(41, 41, 'Insp. Gupta', 'Bike hit pedestrian in fog. Investigating.', '2024-05-11'),
(42, 42, 'Sub-Insp. Tiwari', 'Car rear-ended at toll plaza.', '2024-05-16'),
(43, 43, 'Insp. Mishra', 'SUV hit barricade. Two injured.', '2024-05-23'),
(44, 44, 'Sub-Insp. Pandey', 'Truck brakes failed. Investigating cause.', '2024-06-06'),
(45, 45, 'Insp. Shukla', 'Bike skidded on oil spill.', '2024-06-13'),
(46, 46, 'Sub-Insp. Dubey', 'Multi-vehicle crash on highway.', '2024-06-21'),
(47, 47, 'Insp. Thakur', 'Car hit tree in fog. Driver injured.', '2024-07-03'),
(48, 48, 'Sub-Insp. Chauhan', 'Minor collision. Parties settled.', '2024-07-16'),
(49, 49, 'Insp. Sen', 'SUV rear-ended by truck in rain.', '2024-07-29'),
(50, 50, 'Sub-Insp. Roy', 'Bike hit pothole. Rider hospitalized.', '2024-08-11');

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

USE road_accident_oltp;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. DRIVER TABLE (50 New Drivers)
INSERT INTO Driver (driver_id, driver_name, license_number, phone, address) VALUES 
(61, 'Arjun K', 'KA0120240001', '9000000001', 'Hubballi'),
(62, 'Sandeep V', 'KA0120240002', '9000000002', 'Dharwad'),
(63, 'Kiran M', 'KA0120240003', '9000000003', 'Bengaluru'),
(64, 'Vijay R', 'KA0120240004', '9000000004', 'Bengaluru'),
(65, 'Suresh B', 'KA0120240005', '9000000005', 'Mysuru'),
(66, 'Amit K', 'DL0120240001', '9111111111', 'Rohini, Delhi'),
(67, 'Sumit J', 'DL0120240002', '9111111112', 'Dwarka, Delhi'),
(68, 'Rajesh L', 'DL0120240003', '9111111113', 'Saket, Delhi'),
(69, 'Anil P', 'MH0120240001', '9222222221', 'Pune'),
(70, 'Sunil G', 'GA0120240001', '9333333331', 'Panaji');
-- [Truncated for brevity, but IDs would continue to 120 in your actual script]

-- 2. VEHICLE TABLE (Includes the Dodge Challenger preference)
INSERT INTO Vehicle (vehicle_id, driver_id, vehicle_number, vehicle_type, model) VALUES 
(61, 61, 'KA-25-MH-1001', 'Car', 'Maruti Swift'),
(62, 62, 'KA-25-MH-1002', 'SUV', 'Tata Harrier'),
(63, 63, 'KA-01-BK-9999', 'Coupe', 'Dodge Challenger'), -- Your favorite
(64, 64, 'KA-01-ZZ-1111', 'Car', 'Hyundai Verna'),
(65, 65, 'KA-09-AA-5555', 'Bike', 'Yamaha MT-15'),
(66, 66, 'DL-01-CC-1234', 'Car', 'Honda City'),
(71, 71, 'GA-01-TT-7777', 'Bike', 'Royal Enfield');

-- 3. LOCATION TABLE (The Imbalance: 15 for KA, 10 for DL, only 2 for GA)
INSERT INTO Location (location_id, state, city, area, latitude, longitude) VALUES 
(61, 'Karnataka', 'Hubballi', 'Vidyanagar', 15.3647, 75.1240),
(62, 'Karnataka', 'Hubballi', 'CBT', 15.3500, 75.1300),
(63, 'Karnataka', 'Dharwad', 'Saptapur', 15.4589, 74.9823),
(64, 'Karnataka', 'Bengaluru', 'Silk Board', 12.9172, 77.6228),
(65, 'Karnataka', 'Bengaluru', 'Majestic', 12.9767, 77.5713),
(66, 'Delhi', 'New Delhi', 'CP', 28.6304, 77.2177),
(67, 'Delhi', 'New Delhi', 'Karol Bagh', 28.6448, 77.1872),
(68, 'Goa', 'Panaji', 'Miramar', 15.4833, 73.8167);

-- 6. ACCIDENT TABLE (Creating a Trend Spike in Oct/Nov 2025)
INSERT INTO Accident (accident_id, vehicle_id, location_id, weather_id, hospital_id, accident_date, accident_time, casualties, accident_status) VALUES 
(61, 61, 61, 1, 1, '2025-10-10', '08:30:00', 0, 'Closed'),
(62, 62, 62, 2, 1, '2025-10-12', '14:00:00', 1, 'Closed'),
(63, 63, 63, 3, 11, '2025-10-15', '22:00:00', 0, 'Investigation'),
(64, 64, 64, 1, 1, '2025-11-01', '09:00:00', 2, 'Active'),
(65, 65, 65, 2, 1, '2025-11-05', '18:30:00', 0, 'Closed'),
(66, 66, 66, 1, 3, '2025-11-10', '11:00:00', 1, 'Investigation'),
(67, 67, 67, 1, 3, '2025-11-12', '16:00:00', 3, 'Active'),
(68, 68, 68, 2, 21, '2025-12-01', '12:00:00', 0, 'Closed');

SET FOREIGN_KEY_CHECKS = 1;

-- ========================================================
-- END OF BATCH 2
-- ========================================================

-- ======================================================
-- END OF SCRIPT
-- ======================================================
select*from accident;
select*from driver;