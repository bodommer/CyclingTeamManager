-- =======================================================================================================
-- This script creates a schema for Cycling Team Management system (inspiration: procyclingstats.com)
-- Author: Andrej Jurco
-- =======================================================================================================

USE CyclingTeamManager
GO

BEGIN TRANSACTION CreateSchema

CREATE TABLE Cyclist
(
	id int Identity(1,1) PRIMARY KEY,
	first_name varchar(255),
	last_name varchar(255) NOT NULL,
	dob date,
	pob varchar(255),
	nationality varchar(255)
)
GO

CREATE TABLE Team 
(
	id int Identity(1,1) PRIMARY KEY,
	team_name varchar(255) NOT NULL,
	country varchar(255),
	created smallint, -- year in which the team was established
	CHECK (created < 2500 AND created > 1890)
)
GO

CREATE TABLE race 
(
	id int Identity(1,1) PRIMARY KEY,
	race_name varchar(255) NOT NULL,
	starts date NOT NULL,
	ends date NOT NULL,
	stages tinyint,
	organizer varchar(255),
	season smallint,
	distance smallint,
	CHECK (stages > 0 AND stages < 30),
	CHECK (season > 1890 AND season < 2500),
	CHECK (distance > 0),
	CHECK (starts <= ends)
)
GO

CREATE TABLE stage
(
	id int Identity(1,1) PRIMARY KEY,
	stage_number tinyint NOT NULL,
	stage_date date NOT NULL,
	start_city varchar(255),
	end_city varchar(255),
	distance smallint,
	race_id int NOT NULL FOREIGN KEY REFERENCES race(id) ON DELETE CASCADE
)
GO

CREATE TABLE results
(
	id int Identity(1,1) PRIMARY KEY,
	placement smallint NOT NULL,
	seconds_behind_winner int NOT NULL,
	overall_seconds_behind_winner int NOT NULL,
	cyclist_id int FOREIGN KEY REFERENCES cyclist(id) ON DELETE CASCADE,
	stage_id int FOREIGN KEY REFERENCES stage(id) ON DELETE CASCADE,
	CHECK (seconds_behind_winner >= -3) -- -1 symbolizes 'DNS', -2 symbolizes 'DNF', -3 symbolizes 'DSQ'
)
GO

CREATE TABLE start_list 
(
	id int Identity(1,1) PRIMARY KEY,
	start_number int,
	race_id int FOREIGN KEY REFERENCES race(id) ON DELETE CASCADE,
	cyclist_id int FOREIGN KEY REFERENCES cyclist(id) ON DELETE CASCADE
)
GO

CREATE TABLE contract
(
	id int Identity(1,1) PRIMARY KEY,
	contract_start date NOT NULL,
	contract_end date NOT NULL,
	salary int,
	team_id int FOREIGN KEY REFERENCES team(id) ON DELETE CASCADE,
	cyclist_id int FOREIGN KEY REFERENCES cyclist(id) ON DELETE CASCADE
)
GO

-- Checks if a newly added/modified contract(s) do(es) not collide with other contracts of given cyclist
CREATE TRIGGER contract_date_check
ON contract
AFTER INSERT, UPDATE
AS
	IF EXISTS (SELECT *
		   FROM contract AS c,
		   inserted AS i
		   WHERE c.cyclist_id = i.cyclist_id
				AND (
					c.contract_start < i.contract_end
					OR c.contract_end > i.contract_start
					)				
		   )
		BEGIN 
			RAISERROR('You cannot insert a contract that ends after the start of another or
			starts before existing contract expires!', 15, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END;
GO

-- Checks whether the rider for which we want to insert a stage result is actually on the start list of the stage/race
CREATE TRIGGER stage_result_validity_check
ON results
AFTER INSERT, UPDATE
AS
	DECLARE @race_id int;
	SET @race_id  = (SELECT stage.race_id FROM stage, inserted where stage.id = inserted.id);
	IF NOT EXISTS (SELECT * 
				FROM start_list as sl,
				inserted as i
				WHERE i.cyclist_id = sl.cyclist_id
				AND sl.race_id = @race_id)
		BEGIN
						RAISERROR('You cannot insert a stage result for a rider that is not signed up for the stage/race!', 20, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END;
GO	

CREATE INDEX stage_race_fk ON stage(race_id);
CREATE INDEX results_cyclist ON results(cyclist_id);
CREATE INDEX results_stage ON results(stage_id);
CREATE INDEX start_list_cyclist ON start_list(cyclist_id);
CREATE INDEX start_list_race ON start_list(race_id);
CREATE INDEX contract_cyclist ON contract(cyclist_id);
CREATE INDEX contract_team ON contract(team_id);
CREATE INDEX result_placement ON results(stage_id, placement);

ROLLBACK TRANSACTION

--commit transaction
