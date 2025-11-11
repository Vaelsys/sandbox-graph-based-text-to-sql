-- Sample Data for Video Analytics Events Database (PostgreSQL)
-- This file contains realistic fake data for testing and development

-- Insert sample sources (cameras)
INSERT INTO source (name, location, source_type, configuration, is_active) VALUES
('Camera-Entrance-Main', 'Building A - Main Entrance', 'camera', '{"ip": "192.168.1.101", "resolution": "1920x1080", "fps": 30}'::jsonb, true),
('Camera-Parking-North', 'North Parking Lot - Gate 1', 'camera', '{"ip": "192.168.1.102", "resolution": "1920x1080", "fps": 25}'::jsonb, true),
('Camera-Parking-South', 'South Parking Lot - Gate 2', 'camera', '{"ip": "192.168.1.103", "resolution": "2560x1440", "fps": 30}'::jsonb, true),
('Camera-Loading-Dock', 'Loading Dock - Rear Entrance', 'camera', '{"ip": "192.168.1.104", "resolution": "1920x1080", "fps": 25}'::jsonb, true),
('Camera-Lobby', 'Building A - Main Lobby', 'camera', '{"ip": "192.168.1.105", "resolution": "1920x1080", "fps": 30}'::jsonb, true),
('Camera-Exit-West', 'West Exit - Emergency', 'camera', '{"ip": "192.168.1.106", "resolution": "1280x720", "fps": 20}'::jsonb, false);

-- Insert sample events (spanning the last 7 days)
-- License plate detection events
INSERT INTO event (source_id, event_type_id, start_timestamp, end_timestamp, confidence, bounding_box, frame_number, video_timestamp, status, metadata) VALUES
-- Day 1 (7 days ago)
(2, 1, NOW() - INTERVAL '7 days' + INTERVAL '8 hours 15 minutes', NOW() - INTERVAL '7 days' + INTERVAL '8 hours 15 minutes 3 seconds', 0.9845, '245,180,420,180', 14850, 495000, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 15}'::jsonb),
(2, 1, NOW() - INTERVAL '7 days' + INTERVAL '9 hours 22 minutes', NOW() - INTERVAL '7 days' + INTERVAL '9 hours 22 minutes 2 seconds', 0.9621, '312,195,390,165', 16920, 564000, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 12}'::jsonb),
(3, 1, NOW() - INTERVAL '7 days' + INTERVAL '10 hours 45 minutes', NOW() - INTERVAL '7 days' + INTERVAL '10 hours 45 minutes 4 seconds', 0.9512, '198,210,445,195', 19350, 645000, 'active', '{"camera_zone": "south_gate", "alert_level": "normal", "vehicle_speed_kmh": 18}'::jsonb),

-- Day 2 (6 days ago)
(2, 1, NOW() - INTERVAL '6 days' + INTERVAL '7 hours 30 minutes', NOW() - INTERVAL '6 days' + INTERVAL '7 hours 30 minutes 3 seconds', 0.9734, '267,175,408,172', 13500, 450000, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 14}'::jsonb),
(3, 1, NOW() - INTERVAL '6 days' + INTERVAL '8 hours 12 minutes', NOW() - INTERVAL '6 days' + INTERVAL '8 hours 12 minutes 2 seconds', 0.9889, '223,188,425,180', 14760, 492000, 'active', '{"camera_zone": "south_gate", "alert_level": "normal", "vehicle_speed_kmh": 16}'::jsonb),
(4, 1, NOW() - INTERVAL '6 days' + INTERVAL '14 hours 25 minutes', NOW() - INTERVAL '6 days' + INTERVAL '14 hours 25 minutes 5 seconds', 0.9456, '301,205,398,168', 25875, 862500, 'active', '{"camera_zone": "loading_dock", "alert_level": "normal", "vehicle_speed_kmh": 8, "vehicle_category": "delivery"}'::jsonb),

-- Day 3 (5 days ago) - Including some suspicious activity
(2, 1, NOW() - INTERVAL '5 days' + INTERVAL '2 hours 15 minutes', NOW() - INTERVAL '5 days' + INTERVAL '2 hours 15 minutes 3 seconds', 0.9623, '289,192,412,175', 4050, 135000, 'active', '{"camera_zone": "north_gate", "alert_level": "high", "vehicle_speed_kmh": 45, "speeding": true}'::jsonb),
(3, 1, NOW() - INTERVAL '5 days' + INTERVAL '9 hours 40 minutes', NOW() - INTERVAL '5 days' + INTERVAL '9 hours 40 minutes 4 seconds', 0.9701, '234,201,439,186', 17400, 580000, 'active', '{"camera_zone": "south_gate", "alert_level": "normal", "vehicle_speed_kmh": 13}'::jsonb),
(2, 1, NOW() - INTERVAL '5 days' + INTERVAL '23 hours 45 minutes', NOW() - INTERVAL '5 days' + INTERVAL '23 hours 45 minutes 2 seconds', 0.8934, '178,215,456,192', 42825, 1427500, 'active', '{"camera_zone": "north_gate", "alert_level": "medium", "vehicle_speed_kmh": 11, "after_hours": true}'::jsonb),

-- Day 4 (4 days ago)
(2, 1, NOW() - INTERVAL '4 days' + INTERVAL '7 hours 55 minutes', NOW() - INTERVAL '4 days' + INTERVAL '7 hours 55 minutes 3 seconds', 0.9812, '256,183,418,178', 14265, 475500, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 17}'::jsonb),
(3, 1, NOW() - INTERVAL '4 days' + INTERVAL '11 hours 20 minutes', NOW() - INTERVAL '4 days' + INTERVAL '11 hours 20 minutes 4 seconds', 0.9567, '211,198,432,181', 20400, 680000, 'active', '{"camera_zone": "south_gate", "alert_level": "normal", "vehicle_speed_kmh": 19}'::jsonb),
(4, 1, NOW() - INTERVAL '4 days' + INTERVAL '15 hours 10 minutes', NOW() - INTERVAL '4 days' + INTERVAL '15 hours 10 minutes 6 seconds', 0.9423, '298,208,401,172', 27300, 910000, 'active', '{"camera_zone": "loading_dock", "alert_level": "normal", "vehicle_speed_kmh": 7, "vehicle_category": "delivery"}'::jsonb),

-- Day 5 (3 days ago)
(2, 1, NOW() - INTERVAL '3 days' + INTERVAL '8 hours 5 minutes', NOW() - INTERVAL '3 days' + INTERVAL '8 hours 5 minutes 3 seconds', 0.9756, '273,187,415,176', 14550, 485000, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 16}'::jsonb),
(3, 1, NOW() - INTERVAL '3 days' + INTERVAL '12 hours 35 minutes', NOW() - INTERVAL '3 days' + INTERVAL '12 hours 35 minutes 2 seconds', 0.9634, '245,194,428,183', 22650, 755000, 'active', '{"camera_zone": "south_gate", "alert_level": "normal", "vehicle_speed_kmh": 14}'::jsonb),

-- Day 6 (2 days ago) - More varied events
(2, 1, NOW() - INTERVAL '2 days' + INTERVAL '6 hours 45 minutes', NOW() - INTERVAL '2 days' + INTERVAL '6 hours 45 minutes 3 seconds', 0.9678, '261,181,421,179', 12150, 405000, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 15}'::jsonb),
(3, 1, NOW() - INTERVAL '2 days' + INTERVAL '10 hours 18 minutes', NOW() - INTERVAL '2 days' + INTERVAL '10 hours 18 minutes 4 seconds', 0.9823, '229,199,436,185', 18540, 618000, 'active', '{"camera_zone": "south_gate", "alert_level": "normal", "vehicle_speed_kmh": 17}'::jsonb),
(2, 1, NOW() - INTERVAL '2 days' + INTERVAL '19 hours 50 minutes', NOW() - INTERVAL '2 days' + INTERVAL '19 hours 50 minutes 2 seconds', 0.9245, '284,189,409,174', 35700, 1190000, 'active', '{"camera_zone": "north_gate", "alert_level": "medium", "vehicle_speed_kmh": 12, "after_hours": true}'::jsonb),

-- Day 7 (yesterday)
(2, 1, NOW() - INTERVAL '1 day' + INTERVAL '7 hours 25 minutes', NOW() - INTERVAL '1 day' + INTERVAL '7 hours 25 minutes 3 seconds', 0.9801, '268,185,419,177', 13350, 445000, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 18}'::jsonb),
(3, 1, NOW() - INTERVAL '1 day' + INTERVAL '9 hours 52 minutes', NOW() - INTERVAL '1 day' + INTERVAL '9 hours 52 minutes 3 seconds', 0.9712, '238,196,431,182', 17760, 592000, 'active', '{"camera_zone": "south_gate", "alert_level": "normal", "vehicle_speed_kmh": 15}'::jsonb),
(4, 1, NOW() - INTERVAL '1 day' + INTERVAL '13 hours 40 minutes', NOW() - INTERVAL '1 day' + INTERVAL '13 hours 40 minutes 5 seconds', 0.9534, '305,206,395,170', 24600, 820000, 'active', '{"camera_zone": "loading_dock", "alert_level": "normal", "vehicle_speed_kmh": 9, "vehicle_category": "delivery"}'::jsonb),

-- Today
(2, 1, NOW() - INTERVAL '8 hours 10 minutes', NOW() - INTERVAL '8 hours 10 minutes 3 seconds', 0.9867, '271,183,417,178', 14700, 490000, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 16}'::jsonb),
(3, 1, NOW() - INTERVAL '5 hours 30 minutes', NOW() - INTERVAL '5 hours 30 minutes 2 seconds', 0.9745, '242,197,433,184', 9900, 330000, 'active', '{"camera_zone": "south_gate", "alert_level": "normal", "vehicle_speed_kmh": 14}'::jsonb),
(2, 1, NOW() - INTERVAL '2 hours 15 minutes', NOW() - INTERVAL '2 hours 15 minutes 3 seconds', 0.9623, '265,186,420,176', 4050, 135000, 'active', '{"camera_zone": "north_gate", "alert_level": "normal", "vehicle_speed_kmh": 17}'::jsonb);

-- Motion detection events
INSERT INTO event (source_id, event_type_id, start_timestamp, end_timestamp, confidence, frame_number, video_timestamp, status, metadata) VALUES
(5, 2, NOW() - INTERVAL '3 days' + INTERVAL '22 hours 15 minutes', NOW() - INTERVAL '3 days' + INTERVAL '22 hours 15 minutes 12 seconds', 0.8823, 39825, 1327500, 'active', '{"detection_zone": "lobby_area", "motion_intensity": "low"}'::jsonb),
(5, 2, NOW() - INTERVAL '2 days' + INTERVAL '8 hours 45 minutes', NOW() - INTERVAL '2 days' + INTERVAL '8 hours 45 minutes 8 seconds', 0.9156, 15750, 525000, 'active', '{"detection_zone": "lobby_area", "motion_intensity": "medium"}'::jsonb),
(5, 2, NOW() - INTERVAL '1 day' + INTERVAL '14 hours 30 minutes', NOW() - INTERVAL '1 day' + INTERVAL '14 hours 30 minutes 15 seconds', 0.9421, 26100, 870000, 'active', '{"detection_zone": "lobby_area", "motion_intensity": "high"}'::jsonb);

-- Person detection events
INSERT INTO event (source_id, event_type_id, start_timestamp, end_timestamp, confidence, bounding_box, frame_number, video_timestamp, status, metadata) VALUES
(5, 3, NOW() - INTERVAL '4 days' + INTERVAL '9 hours 20 minutes', NOW() - INTERVAL '4 days' + INTERVAL '9 hours 20 minutes 45 seconds', 0.9512, '512,280,180,420', 16800, 560000, 'active', '{"person_count": 1, "location": "lobby_entrance"}'::jsonb),
(5, 3, NOW() - INTERVAL '2 days' + INTERVAL '11 hours 40 minutes', NOW() - INTERVAL '2 days' + INTERVAL '11 hours 40 minutes 32 seconds', 0.9345, '445,295,165,395', 21000, 700000, 'active', '{"person_count": 3, "location": "lobby_entrance"}'::jsonb),
(1, 3, NOW() - INTERVAL '1 day' + INTERVAL '8 hours 15 minutes', NOW() - INTERVAL '1 day' + INTERVAL '8 hours 15 minutes 28 seconds', 0.9678, '389,312,152,388', 14850, 495000, 'active', '{"person_count": 2, "location": "main_entrance"}'::jsonb);

-- Insert license plate specific data
INSERT INTO license_plate_event (event_id, plate_number, plate_country, plate_state, plate_type, vehicle_type, vehicle_color, vehicle_make, vehicle_model, direction, ocr_confidence) VALUES
-- Day 1 events
(1, 'ABC1234', 'USA', 'California', 'passenger', 'car', 'silver', 'Toyota', 'Camry', 'entry', 0.9823),
(2, 'XYZ5678', 'USA', 'Texas', 'passenger', 'car', 'black', 'Honda', 'Accord', 'entry', 0.9701),
(3, 'DEF9012', 'USA', 'California', 'passenger', 'suv', 'white', 'Ford', 'Explorer', 'exit', 0.9589),

-- Day 2 events
(4, 'GHI3456', 'USA', 'Nevada', 'passenger', 'car', 'blue', 'Chevrolet', 'Malibu', 'entry', 0.9712),
(5, 'JKL7890', 'USA', 'California', 'passenger', 'car', 'red', 'Tesla', 'Model 3', 'entry', 0.9867),
(6, 'MNO2345', 'USA', 'California', 'commercial', 'truck', 'white', 'Ford', 'F-150', 'entry', 0.9434),

-- Day 3 events (including suspicious)
(7, 'PQR6789', 'USA', 'California', 'passenger', 'car', 'black', 'BMW', '3 Series', 'entry', 0.9601),
(8, 'STU0123', 'USA', 'Arizona', 'passenger', 'suv', 'gray', 'Jeep', 'Grand Cherokee', 'exit', 0.9678),
(9, 'VWX4567', 'USA', 'California', 'passenger', 'car', 'silver', 'Nissan', 'Altima', 'entry', 0.8912),

-- Day 4 events
(10, 'YZA8901', 'USA', 'California', 'passenger', 'car', 'white', 'Hyundai', 'Elantra', 'entry', 0.9789),
(11, 'BCD2345', 'USA', 'Oregon', 'passenger', 'car', 'blue', 'Mazda', 'CX-5', 'exit', 0.9545),
(12, 'EFG6789', 'USA', 'California', 'commercial', 'truck', 'yellow', 'Mercedes', 'Sprinter', 'entry', 0.9401),

-- Day 5 events
(13, 'HIJ0123', 'USA', 'California', 'passenger', 'car', 'black', 'Audi', 'A4', 'entry', 0.9734),
(14, 'KLM4567', 'USA', 'Washington', 'passenger', 'suv', 'red', 'Toyota', 'RAV4', 'exit', 0.9612),

-- Day 6 events
(15, 'NOP8901', 'USA', 'California', 'passenger', 'car', 'gray', 'Volkswagen', 'Jetta', 'entry', 0.9656),
(16, 'QRS2345', 'USA', 'California', 'passenger', 'car', 'white', 'Honda', 'Civic', 'exit', 0.9801),
(17, 'TUV6789', 'USA', 'Nevada', 'passenger', 'car', 'silver', 'Toyota', 'Corolla', 'entry', 0.9223),

-- Day 7 events (yesterday)
(18, 'WXY0123', 'USA', 'California', 'passenger', 'suv', 'blue', 'Subaru', 'Outback', 'entry', 0.9778),
(19, 'ZAB4567', 'USA', 'California', 'passenger', 'car', 'black', 'Tesla', 'Model Y', 'exit', 0.9689),
(20, 'CDE8901', 'USA', 'California', 'commercial', 'truck', 'white', 'Isuzu', 'NPR', 'entry', 0.9512),

-- Today's events
(21, 'FGH2345', 'USA', 'California', 'passenger', 'car', 'red', 'Kia', 'Forte', 'entry', 0.9845),
(22, 'IJK6789', 'USA', 'Arizona', 'passenger', 'suv', 'gray', 'Ford', 'Escape', 'exit', 0.9723),
(23, 'LMN0123', 'USA', 'California', 'passenger', 'car', 'white', 'Chevrolet', 'Cruze', 'entry', 0.9601);

-- Add some archived/flagged events
UPDATE event SET status = 'false_positive' WHERE id IN (9, 17);
UPDATE event SET status = 'archived' WHERE start_timestamp < NOW() - INTERVAL '6 days';

-- Summary statistics (run these to verify data)
-- SELECT COUNT(*) as total_events FROM event;
-- SELECT COUNT(*) as license_plate_events FROM license_plate_event;
-- SELECT status, COUNT(*) FROM event GROUP BY status;
-- SELECT COUNT(*) as today_events FROM event WHERE start_timestamp >= CURRENT_DATE;