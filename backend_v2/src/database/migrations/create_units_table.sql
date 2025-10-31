-- Migration: Create units table
-- Description: Creates table for managing product units (satuan)
-- Date: 2025-10-31

-- Create units table
CREATE TABLE IF NOT EXISTS units (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP DEFAULT NULL
);

-- Create indexes
CREATE INDEX idx_units_name ON units(name);
CREATE INDEX idx_units_is_active ON units(is_active);
CREATE INDEX idx_units_deleted_at ON units(deleted_at);

-- Insert default units
INSERT INTO units (name, description, is_active) VALUES
('PCS', 'Pieces - Satuan per potong/buah', TRUE),
('KG', 'Kilogram - Satuan per kilogram', TRUE),
('GRAM', 'Gram - Satuan per gram', TRUE),
('LITER', 'Liter - Satuan per liter', TRUE),
('ML', 'Mililiter - Satuan per mililiter', TRUE),
('BOX', 'Box - Satuan per kotak', TRUE),
('PACK', 'Pack - Satuan per pack/bungkus', TRUE),
('DUS', 'Dus - Satuan per dus', TRUE),
('LUSIN', 'Lusin - Satuan per lusin (12 buah)', TRUE),
('METER', 'Meter - Satuan per meter', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Add comment to table
COMMENT ON TABLE units IS 'Table for managing product units (satuan)';
COMMENT ON COLUMN units.id IS 'Primary key';
COMMENT ON COLUMN units.name IS 'Unit name (unique, uppercase)';
COMMENT ON COLUMN units.description IS 'Unit description';
COMMENT ON COLUMN units.is_active IS 'Whether the unit is active';
COMMENT ON COLUMN units.created_at IS 'Timestamp when unit was created';
COMMENT ON COLUMN units.updated_at IS 'Timestamp when unit was last updated';
COMMENT ON COLUMN units.deleted_at IS 'Timestamp when unit was soft deleted';
