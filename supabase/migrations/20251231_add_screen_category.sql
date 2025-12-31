-- Migration: Add category field to screen_definitions table
-- Date: 2025-12-31
-- Description: Adds screen_category enum and category column to organize screens into workspace, wellbeing, and settings groups

-- Create screen category enum type
CREATE TYPE screen_category AS ENUM ('workspace', 'wellbeing', 'settings');

-- Add category column to screen_definitions with default value
ALTER TABLE screen_definitions
ADD COLUMN category screen_category NOT NULL DEFAULT 'workspace';

-- Update existing system screens with appropriate categories
-- This assumes system screens already exist from the seeder

-- Workspace screens remain as 'workspace' (already the default)
-- No update needed for: inbox, today, upcoming, next_actions, projects, labels, values

-- Update wellbeing screens
UPDATE screen_definitions
SET category = 'wellbeing'
WHERE screen_id IN ('wellbeing', 'journal', 'trackers')
  AND is_system = true;

-- Update settings screens  
UPDATE screen_definitions
SET category = 'settings'
WHERE screen_id IN ('allocation_settings', 'navigation_settings', 'settings')
  AND is_system = true;

-- Create index for better query performance when filtering by category
CREATE INDEX idx_screen_definitions_category ON screen_definitions(category);

-- Create index for category + is_system combination (common query pattern)
CREATE INDEX idx_screen_definitions_category_system ON screen_definitions(category, is_system);

COMMENT ON COLUMN screen_definitions.category IS 'Categorizes screens: workspace (core task/project views), wellbeing (health tracking), settings (configuration)';
COMMENT ON TYPE screen_category IS 'Screen categories for organizing navigation: workspace, wellbeing, settings';
