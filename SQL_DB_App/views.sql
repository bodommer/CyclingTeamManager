-- =======================================================================================================
-- Creates useful views for the application.
-- Author: Andrej Jurco
-- =======================================================================================================

USE CyclingTeamManager
GO

if object_id('active_cyclists', 'V') is not null drop view active_cyclists
go
-- lists all cyclist names with a valid contract at the time of execution
CREATE VIEW active_cyclists
AS
	SELECT 
		Cyclist.first_name AS 'Name',
		Cyclist.last_name AS 'Last Name',
		contr.contract_end AS 'Contract expiry date'
	FROM 
		(Cyclist
			RIGHT JOIN (
				SELECT * 
				FROM 
					contract 
				WHERE 
					contract_start < GETDATE() AND 
					contract_end < GETDATE()) contr 
			ON Cyclist.id = contr.cyclist_id)
		LEFT JOIN Team 
			ON contr.team_id = Team.id
GO

if object_id('cyclist_season_results', 'V') is not null drop view cyclist_season_results
go
-- lists all cyclist names with a valid
CREATE VIEW cyclist_season_results
AS
	SELECT  
		c.first_name AS 'Name', 
		c.last_name AS 'Last name', 
		rc.race_name AS 'Race Name', 
		s.stage_number AS 'Stage no.', 
		r.placement AS 'Result', 
		CONVERT(varchar, DATEADD(ms, r.seconds_behind_winner * 1000, 0), 114) AS 'Gap to winner'
	FROM 
		stage s
		JOIN results r 
			ON s.id = r.stage_id
		JOIN race rc 
			ON s.race_id = rc.id
		JOIN Cyclist c 
			ON c.id = r.cyclist_id
	WHERE 
		(SELECT YEAR(s.stage_date)) = (SELECT YEAR(CURRENT_TIMESTAMP))
GO

if object_id('stage_winners', 'V') is not null drop view stage_winners
go
-- lists winners of stages of each race
CREATE VIEW stage_winners 
AS
	SELECT 		
		r."Name" AS 'Name', 
		r."Last Name" AS 'Last Name', 
		r."Race Name" AS 'Race Name', 
		r."Stage no." AS 'Stage no.'
	FROM 
		cyclist_season_results r 
	WHERE 
		r."Result" = 1
GO

if object_id('team_roster', 'V') is not null drop view team_roster
go
-- returns a table of cyclists and the team they are currently under contract with
CREATE VIEW team_roster
AS
	SELECT 
		c.first_name AS "Name",
		c.last_name AS "Last Name",
		t.team_name AS "Team",
		YEAR(co.contract_end) AS "Contract til"
	FROM 
		Cyclist c 
		JOIN (	SELECT * 
				FROM 
					contract 
				WHERE 
					contract.contract_end >= GETDATE()) co 
			ON c.id = co.cyclist_id
		JOIN Team t 
			ON co.team_id = t.id
GO

if object_id('overall_race_winners', 'V') is not null drop view overall_race_winners
go

CREATE VIEW overall_race_winners
AS
	SELECT
		r.race_name AS 'Race Name',
		r.starts AS 'From',
		r.ends AS 'To',
		r.stages AS 'Stages',
		c.first_name + ' ' + c.last_name AS 'Winner'
	FROM
		race r
		LEFT JOIN stage s 
			ON s.race_id = r.id
		LEFT JOIN results rs 
			ON s.id = rs.stage_id
		LEFT JOIN Cyclist c
			ON c.id = rs.cyclist_id
	WHERE
		s.stage_number = r.stages
		AND rs.seconds_behind_winner = 0
GO

if object_id('race_stage_info', 'V') is not null drop view race_stage_info
GO
-- info of stages with their race info
CREATE VIEW race_stage_info
AS 
	SELECT  
		r.race_name AS 'Race Name',
		r.organizer AS 'Organizer',
		r.starts AS 'Starts',
		r.ends AS 'Ends',
		r.distance AS 'Total distance',
		s.stage_number AS 'Stage no.',
		s.stage_date AS 'Stage date',
		s.start_city AS 'From',
		s.end_city AS 'To',
		s.distance AS 'Distance'
	FROM stage s
		JOIN race r 
			ON s.race_id = r.id
GO

IF OBJECT_ID('dnf_count', 'V') IS NOT NULL DROP VIEW dnf_count
GO
-- returns the number of DNF/DNS/DSQ the rider has done in his/her entire career
CREATE VIEW dnf_count
AS
	SELECT
		c.first_name + ' ' + c.last_name AS 'Name',
		counts.cnt AS 'DNF/DNS/DSQ Count'
	FROM Cyclist c
		JOIN (	SELECT 
					COUNT(*) AS cnt, 
					r.cyclist_id as cid 
				FROM 
					results r 
				WHERE 
					r.placement < 0
				GROUP BY 
					r.cyclist_id) counts
			ON counts.cid = c.id
GO

IF OBJECT_ID('racing_calendar', 'V') IS NOT NULL DROP VIEW racing_calendar
GO
-- returns the race calendar for the current season (if the rider appears on the start list of the race)
CREATE VIEW racing_calendar
AS
	SELECT 
		c.id AS 'Cyclist ID',
		r.race_name AS 'Race',
		r.starts AS 'Start Date',
		r.ends AS 'End Date',
		r.distance AS 'Race Distance'
	FROM
		start_list s
		JOIN race r 
			ON s.race_id = r.id
		JOIN Cyclist c 
			ON s.cyclist_id = c.id
	WHERE 
		r.season = YEAR(CURRENT_TIMESTAMP)
GO

IF OBJECT_ID('free_agents', 'V') IS NOT NULL DROP VIEW free_agents
GO
-- lists all riders whose contract expires by the end of the current year and there is no next signed contract for them
CREATE VIEW free_agents
AS
	SELECT 
		c.first_name + ' ' + c.last_name AS 'Name',
		ct.contract_start AS 'Last contract from',
		ct.contract_end AS 'Contract expires',
		ct.salary AS 'Current Salary',
		t.team_name AS 'Current Team'
	FROM Cyclist c
		JOIN (SELECT MAX(cn.contract_end) AS 'end', cn.cyclist_id as 'cyc_id' FROM contract cn GROUP BY cn.cyclist_id) contr 
			ON contr."cyc_id" = c.id
		JOIN contract ct 
			ON ct.contract_end = contr."end" AND ct.cyclist_id = c.id
		JOIN Team t
			ON t.id = ct.team_id
	WHERE
		EXISTS(SELECT * FROM contract cn WHERE cn.cyclist_id = c.id 
				AND cn.contract_end > CURRENT_TIMESTAMP 
				AND YEAR(cn.contract_end) = YEAR(CURRENT_TIMESTAMP))
		AND NOT EXISTS (SELECT *  FROM contract cn WHERE cn.cyclist_id = c.id AND cn.contract_start > CURRENT_TIMESTAMP)
GO