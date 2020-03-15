-- =======================================================================================================
-- Deletes the whole scehma created by CreateSchema.sql
-- Author: Andrej Jurco
-- =======================================================================================================

Use CyclingTeamManager
GO

UPDATE STATISTICS Cyclist;
UPDATE STATISTICS Team;
UPDATE STATISTICS race;
UPDATE STATISTICS stage;
UPDATE STATISTICS results;
UPDATE STATISTICS contract;
UPDATE STATISTICS start_list;

CREATE STATISTICS cyclist_name ON Cyclist(first_name, last_name) with fullscan;
CREATE STATISTICS race_name on race(race_name) with fullscan;





