-- =======================================================================================================
-- Deletes all full scan statistics created by the generate_stats.sql script.
-- Author: Andrej Jurco
-- =======================================================================================================

USE CyclingTeamManager
GO

DROP STATISTICS Cyclist.cyclist_name
DROP STATISTICS race.race_name