-- =======================================================================================================
-- Testing script for all views and procedures.
-- Author: Andrej Jurco
-- =======================================================================================================

USE CyclingTeamManager
GO

-- Add some Teams
exec CreateTeam 'BORA - Hansgrohe', 'Germany', 2016;
exec CreateTeam 'Deceuninck - Quickstep', 'Belgium', 1998;
exec CreateTeam 'Phoenix - Alpecin', 'Germany', 2020;
exec CreateTeam 'Team Saxo Bank', 'Russia', 2008;
-- Add some Cyclists 
exec AddCyclist 'Peter', 'Sagan', NULL, NULL, 'Slovakia';
exec AddCyclist 'Juraj', 'Sagan', NULL, NULL, 'Slovakia';
exec AddCyclist 'Erik', 'Baska', NULL, NULL, 'Slovakia';
exec AddCyclist 'Petr', 'Vakoc', NULL, NULL, 'Czech Republic';
exec AddCyclist 'Roman', 'Kreuziger', NULL, NULL, 'Czech Republic';
exec AddCyclist 'Zdenek', 'Stybar', NULL, NULL, 'Czech Republic';
-- Add some contracts
exec AddContract '2018-01-01', '2020-12-31', 

-- 
