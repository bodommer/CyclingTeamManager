-- =======================================================================================================
-- Loads initial data.
-- Author: Andrej Jurco
-- =======================================================================================================

USE CyclingTeamManager
GO

INSERT INTO Cyclist (first_name, last_name, dob, pob, nationality)
VALUES
	('Peter', 'Sagan', NULL, NULL, 'Slovakia'),
	('Juraj', 'Sagan', NULL, NULL, 'Slovakia'),
	('Erik', 'Baska', NULL, NULL, 'Slovakia'),
	('Roman', 'Kreuziger', NULL, NULL, 'Czech Republic'),
	('Zdenek', 'Stybar', NULL, NULL, 'Czech Republic'),
	('Petr', 'Vakoc', '1992-07-11', 'Prague', 'Czech Republic'),
	('Leo', 'Konig', NULL, NULL, 'Czech Republic');

INSERT INTO Team (team_name, country, created)
VALUES
	('BORA - Hansgrohe', 'Germany', 2012),
	('Deceuninck - QuickStep', 'Belgium', 1998),
	('Phoenix-Alpecin', 'Germany', 2020),
	('Team Saxo Bank', 'Russia', 2008);

INSERT INTO contract (cyclist_id, team_id, contract_start, contract_end, salary)
VALUES
	(1, 1, '2018-01-01', '2020-12-31', 4500000),
	(1, 1, '2014-01-01', '2017-12-31', 3000000),
	(2, 1, '2018-01-01', '2020-12-31', 300000),
	(3, 1, '2018-01-01', '2020-12-31', 150000),
	(4, 4, '2012-01-01', '2019-12-31', 700000),
	(4, 3, '2020-01-01', '2022-12-31', 500000),
	(3, 1, '2018-01-01', '2020-12-31', 400000),
	(5, 2, '2014-01-01', '2021-12-31', 1800000),
	(6, 3, '2020-01-01', '2023-12-31', 500000),
	(7, 1, '2018-01-01', '2020-06-30', NULL);

INSERT INTO race (race_name, organizer, season, stages, distance, starts, ends)
VALUES
	('Giro d''Italia', 'ASO', 2020, 2, 361, '2020-05-21', '2020-05-22'),
	('Paris-Roubaix', 'RCS', 2020, 1, 258, '2020-04-04', '2020-04-04');

INSERT INTO stage (race_id, distance, stage_date, stage_number, start_city, end_city)
VALUES
	(1, 178, '2020-05-21', 1, 'Roma', 'Genova'),
	(1, 183, '2020-05-22', 2, 'Genova', 'Milano'),
	(2, 258, '2020-04-04', 1, 'Paris', 'Roubaix');

INSERT INTO start_list (cyclist_id, race_id, start_number)
VALUES 
	(1, 1, 1),
	(1, 2, 1),
	(2, 1, 2),
	(3, 1, 3),
	(3, 2, 2),
	(4, 2, 3),
	(5, 1, 4),
	(6, 1, 5),
	(6, 2, 4),
	(7, 1, 6);

INSERT INTO results (cyclist_id, stage_id, overall_seconds_behind_winner, seconds_behind_winner, placement)
VALUES
	(
