-- Video Analytics Events Database Schema
-- Compatible with MySQL 5.7+, PostgreSQL 9.5+, and SQLite 3.8+

-- Table: source
-- Stores information about video sources (cameras, feeds, etc.)
CREATE TABLE source (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    source_type VARCHAR(50) NOT NULL, -- 'camera', 'video_file', 'stream', etc.
    configuration TEXT, -- JSON string for source-specific config
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY idx_source_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: event_type
-- Catalog of event types that can be detected
CREATE TABLE event_type (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL UNIQUE, -- 'license_plate', 'person_detected', 'motion', etc.
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- 'vehicle', 'person', 'object', 'motion', etc.
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: event
-- Main events table storing all video analytics events
CREATE TABLE event (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    source_id INTEGER NOT NULL,
    event_type_id INTEGER NOT NULL,
    start_timestamp TIMESTAMP(3) NOT NULL, -- millisecond precision
    end_timestamp TIMESTAMP(3), -- NULL for instantaneous events
    confidence DECIMAL(5,4), -- 0.0000 to 1.0000 confidence score
    bounding_box VARCHAR(100), -- Format: "x,y,width,height" or JSON
    frame_number BIGINT,
    video_timestamp BIGINT, -- milliseconds from video start
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'archived', 'deleted', 'false_positive'
    metadata JSON, -- Flexible storage for additional event data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (source_id) REFERENCES source(id) ON DELETE CASCADE,
    FOREIGN KEY (event_type_id) REFERENCES event_type(id) ON DELETE RESTRICT,
    
    INDEX idx_source_timestamp (source_id, start_timestamp),
    INDEX idx_event_type_timestamp (event_type_id, start_timestamp),
    INDEX idx_start_timestamp (start_timestamp),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: event_metadata
-- Flexible key-value storage for event-specific data
CREATE TABLE event_metadata (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    meta_key VARCHAR(100) NOT NULL,
    meta_value TEXT NOT NULL,
    value_type VARCHAR(20) DEFAULT 'string', -- 'string', 'number', 'boolean', 'json'
    
    FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE,
    
    INDEX idx_event_key (event_id, meta_key),
    INDEX idx_meta_key (meta_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: license_plate_event
-- Specialized table for license plate reading events
CREATE TABLE license_plate_event (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    event_id BIGINT NOT NULL UNIQUE,
    plate_number VARCHAR(20) NOT NULL,
    plate_country VARCHAR(3), -- ISO 3166-1 alpha-3 country code
    plate_state VARCHAR(50), -- State/province if applicable
    plate_type VARCHAR(50), -- 'passenger', 'commercial', 'motorcycle', etc.
    vehicle_type VARCHAR(50), -- 'car', 'truck', 'motorcycle', etc.
    vehicle_color VARCHAR(50),
    vehicle_make VARCHAR(50),
    vehicle_model VARCHAR(50),
    direction VARCHAR(20), -- 'entry', 'exit', 'pass_through'
    ocr_confidence DECIMAL(5,4),
    
    FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE,
    
    INDEX idx_plate_number (plate_number),
    INDEX idx_plate_timestamp (plate_number, start_timestamp),
    INDEX idx_direction (direction)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create a view for easy license plate event querying
CREATE VIEW v_license_plate_event AS
SELECT 
    e.id as event_id,
    s.name as source_name,
    s.location as source_location,
    e.start_timestamp,
    e.end_timestamp,
    e.confidence as detection_confidence,
    lpe.plate_number,
    lpe.plate_country,
    lpe.plate_state,
    lpe.vehicle_type,
    lpe.vehicle_color,
    lpe.direction,
    lpe.ocr_confidence,
    e.bounding_box,
    e.status
FROM event e
JOIN source s ON e.source_id = s.id
JOIN event_type et ON e.event_type_id = et.id
JOIN license_plate_event lpe ON e.id = lpe.event_id
WHERE et.code = 'license_plate';

-- Sample initial data
INSERT INTO event_type (code, name, description, category) VALUES
('license_plate', 'License Plate Detection', 'Automatic license plate recognition event', 'vehicle'),
('motion_detection', 'Motion Detection', 'Motion detected in frame', 'motion'),
('person_detected', 'Person Detection', 'Person detected in frame', 'person'),
('vehicle_detected', 'Vehicle Detection', 'Vehicle detected in frame', 'vehicle'),
('face_detected', 'Face Detection', 'Face detected in frame', 'person');

-- Example query: Get all license plate events from the last 24 hours
-- SELECT * FROM v_license_plate_event 
-- WHERE start_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
-- ORDER BY start_timestamp DESC;

-- Example query: Get events with metadata
-- SELECT e.*, GROUP_CONCAT(CONCAT(em.meta_key, '=', em.meta_value) SEPARATOR '; ') as metadata
-- FROM event e
-- LEFT JOIN event_metadata em ON e.id = em.event_id
-- WHERE e.source_id = 1
-- GROUP BY e.id
-- ORDER BY e.start_timestamp DESC;

-- SQLite Compatibility Notes:
-- For SQLite, replace:
-- 1. INTEGER PRIMARY KEY AUTO_INCREMENT -> INTEGER PRIMARY KEY AUTOINCREMENT
-- 2. BIGINT -> INTEGER
-- 3. TIMESTAMP(3) -> TEXT (store as ISO 8601 format)
-- 4. DECIMAL(5,4) -> REAL
-- 5. ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci -> (remove)
-- 6. ON UPDATE CURRENT_TIMESTAMP -> (remove, handle in application)
-- 7. GROUP_CONCAT -> group_concat (lowercase)