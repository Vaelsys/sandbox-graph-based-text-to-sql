-- Video Analytics Events Database Schema for PostgreSQL 9.5+
-- Optimized for PostgreSQL with JSONB, proper data types, and indexing

-- Table: source
-- Stores information about video sources (cameras, feeds, etc.)
CREATE TABLE source (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    location VARCHAR(255),
    source_type VARCHAR(50) NOT NULL, -- 'camera', 'video_file', 'stream', etc.
    configuration JSONB, -- JSON for source-specific config
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: event_type
-- Catalog of event types that can be detected
CREATE TABLE event_type (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE, -- 'license_plate', 'person_detected', 'motion', etc.
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- 'vehicle', 'person', 'object', 'motion', etc.
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: event
-- Main events table storing all video analytics events
CREATE TABLE event (
    id BIGSERIAL PRIMARY KEY,
    source_id INTEGER NOT NULL,
    event_type_id INTEGER NOT NULL,
    start_timestamp TIMESTAMP(3) NOT NULL, -- millisecond precision
    end_timestamp TIMESTAMP(3), -- NULL for instantaneous events
    confidence NUMERIC(5,4), -- 0.0000 to 1.0000 confidence score
    bounding_box VARCHAR(100), -- Format: "x,y,width,height" or JSON
    frame_number BIGINT,
    video_timestamp BIGINT, -- milliseconds from video start
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'archived', 'deleted', 'false_positive'
    metadata JSONB, -- Flexible storage for additional event data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_event_source FOREIGN KEY (source_id) REFERENCES source(id) ON DELETE CASCADE,
    CONSTRAINT fk_event_type FOREIGN KEY (event_type_id) REFERENCES event_type(id) ON DELETE RESTRICT
);

-- Table: license_plate_event
-- Specialized table for license plate reading events
CREATE TABLE license_plate_event (
    id BIGSERIAL PRIMARY KEY,
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
    ocr_confidence NUMERIC(5,4),
    
    CONSTRAINT fk_license_plate_event FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE
);

-- Indexes for event table
CREATE INDEX idx_event_source_timestamp ON event(source_id, start_timestamp);
CREATE INDEX idx_event_type_timestamp ON event(event_type_id, start_timestamp);
CREATE INDEX idx_event_start_timestamp ON event(start_timestamp);
CREATE INDEX idx_event_status ON event(status);

-- GIN index for fast JSONB queries on metadata
CREATE INDEX idx_event_metadata_gin ON event USING GIN (metadata jsonb_path_ops);

-- Indexes for license_plate_event table
CREATE INDEX idx_license_plate_number ON license_plate_event(plate_number);
CREATE INDEX idx_license_plate_direction ON license_plate_event(direction);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to auto-update updated_at
CREATE TRIGGER update_source_updated_at BEFORE UPDATE ON source
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_updated_at BEFORE UPDATE ON event
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
    e.metadata,
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

-- Example queries for PostgreSQL

-- Get all license plate events from the last 24 hours
-- SELECT * FROM v_license_plate_event 
-- WHERE start_timestamp >= NOW() - INTERVAL '24 hours'
-- ORDER BY start_timestamp DESC;

-- Query JSONB metadata using containment operator
-- SELECT * FROM event
-- WHERE metadata @> '{"alert_level": "high"}'::jsonb
-- ORDER BY start_timestamp DESC;

-- Query JSONB metadata using path extraction
-- SELECT id, start_timestamp, metadata->>'camera_zone' as zone
-- FROM event
-- WHERE metadata->>'alert_level' = 'high'
-- ORDER BY start_timestamp DESC;

-- Query with multiple JSONB conditions
-- SELECT * FROM event
-- WHERE metadata @> '{"alert_level": "high"}'::jsonb
--   AND metadata ? 'camera_zone'
-- ORDER BY start_timestamp DESC;

-- Get event counts by metadata field
-- SELECT metadata->>'camera_zone' as zone, COUNT(*) as event_count
-- FROM event
-- WHERE metadata ? 'camera_zone'
-- GROUP BY metadata->>'camera_zone'
-- ORDER BY event_count DESC;

-- License plate search with partial match
-- SELECT * FROM v_license_plate_event
-- WHERE plate_number ILIKE '%ABC%'
-- ORDER BY start_timestamp DESC
-- LIMIT 100;