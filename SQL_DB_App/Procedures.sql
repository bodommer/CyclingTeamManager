-- =======================================================================================================
-- A set of procedures for manipulating the data in the Cycling Team Manager app.
-- Author: Andrej Jurco
-- =======================================================================================================
USE CyclingTeamManager
GO

if OBJECT_ID('AddCyclist', 'P') IS NOT NULL DROP PROCEDURE AddCyclist
GO

CREATE PROCEDURE AddCyclist
	@firstName varchar(255),
	@lastName varchar(255),
	@birth date,
	@bornAt varchar(255),
	@country varchar(255)
	AS
	BEGIN
		SET NOCOUNT ON	
		-- Last name cannot be empty/null
		if (@lastName IS NULL) RAISERROR ('Last name of the cyclist can not be NULL!', 10, 1)
		-- At least 2 characters (2, because eg. Chinese surnames have 2 characters - Yi,..)
		if len(@lastName) < 2 RAISERROR ('Last name too short!', 10, 1)
		-- check if birth is not null and if it isn't, check that the date is valid (not in the future)
		if (@birth IS NOT NULL AND @birth > GETDATE()) RAISERROR ('Cannot add a cyclist with date of birth later than today!', 15, 1)
		
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO [Cyclist] (first_name, last_name, dob, pob, nationality) 
				VALUES (@firstName, @lastName, @birth, @bornAt, @country)
			COMMIT TRANSACTION
			PRINT 'A new cyclist record was successfully inserted'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error inserting a cyclist!'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('CreateRace', 'P') IS NOT NULL DROP PROCEDURE CreateRace
GO

CREATE PROCEDURE CreateRace
	@name varchar(255),
	@from date,
	@till date,
	@stages tinyint,
	@org varchar(255),
	@season smallint,
	@dist smallint
	AS BEGIN
		SET NOCOUNT ON	
		-- not null check 1
		IF (@from IS NULL) RAISERROR('Race start date cannot be NULL!', 10, 1)
		-- not null check 2
		IF (@till IS NULL) RAISERROR('Race end date cannot be NULL!', 10, 1)
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO [race] (race_name, starts, ends, stages, organizer, season, distance)
				VALUES (@name, @from, @till, @stages, @org, @season, @dist)
			COMMIT TRANSACTION
			PRINT 'A new race was successfully inserted'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error inserting a race!'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('CreateTeam', 'P') IS NOT NULL DROP PROCEDURE CreateTeam
GO

CREATE PROCEDURE CreateTeam
	@name varchar(255),
	@country varchar(255),
	@created smallint -- year of formation
	AS
	BEGIN
		SET NOCOUNT ON
		if (@name IS NULL) RAISERROR('Name of the team can NOT be NULL!', 10, 1);
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO [Team] (team_name, country, created)
				VALUES (@name, @country, @created)
			COMMIT TRANSACTION
			PRINT 'A new team was successfully inserted'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error inserting a new team!'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('AddStageToRace', 'P') IS NOT NULL DROP PROCEDURE AddStageToRace
GO

CREATE PROCEDURE AddStageToRace
	@race_id int,
	@stage_number tinyint,
	@stage_date date,
	@start_city varchar(255),
	@end_city varchar(255),
	@dist smallint
	AS
	BEGIN
		SET NOCOUNT ON	
		-- check if we are adding a stage to an existing race
		IF ((SELECT COUNT(*) FROM [race] AS r WHERE r.id = @race_id) = 0) RAISERROR('It is not possible to add a stage to a non-existing race!', 20, 1);
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO [stage] (stage_number, stage_date, start_city, end_city, distance, race_id)
				VALUES (@stage_number, @stage_date, @start_city, @end_city, @dist, @race_id)
			COMMIT TRANSACTION
			PRINT 'A new stage was successfully inserted'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error inserting a stage!'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('AddResults', 'P') IS NOT NULL DROP PROCEDURE AddResults
GO

-- This procedure is used for a bulk result insertion into a table
-- the xml has format:
-- <results>
--	 <result>
--		<placement> int </placement>
--		<behind1> gap behind in the stage </behind1>
--		<behind2> overall gap behind the leader </behind2>
--		<cyclist> cyclist ID </cyclist>
--		<stage> stage ID </stage>
--   </result>
--</results>

CREATE PROCEDURE AddResults
	@results XML
	AS
	BEGIN
		SET NOCOUNT ON
		
		DECLARE @placement smallint,
				@stage_gap int,
				@overall_gap int,
				@cyclist int,
				@stage int;

		DECLARE result_cursor CURSOR
		FOR SELECT
			@results.value('(/results/result/placement)[1]', 'smallint') AS placement,
			@results.value('(/results/result/behind1)[1]', 'int') AS stage_behind,
			@results.value('(/results/result/behind2)[1]', 'int') AS overall_behind,
			@results.value('(/results/result/cyclist)[1]', 'int') AS cyclist_id,
			@results.value('(/results/result/stage)[1]', 'int') AS stage_id;

		OPEN result_cursor;
		FETCH NEXT FROM result_cursor INTO @placement, @stage_gap, @overall_gap, @cyclist, @stage; 
		WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRANSACTION
				BEGIN TRY
					INSERT INTO [results] (placement, seconds_behind_winner, overall_seconds_behind_winner, cyclist_id, stage_id)
						VALUES (@placement, @stage_gap, @overall_gap, @cyclist, @stage);
					COMMIT TRANSACTION
					PRINT 'A new result was successfully added.'
				END TRY 
				BEGIN CATCH 
					ROLLBACK TRANSACTION
					PRINT 'Error - failed to insert a result from an XML file!'
					PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
				END CATCH

			FETCH NEXT FROM result_cursor INTO @placement, @stage_gap, @overall_gap, @cyclist, @stage; 
		END;
		CLOSE result_cursor;
		DEALLOCATE result_cursor;
	END
GO

if OBJECT_ID('AddContract', 'P') IS NOT NULL DROP PROCEDURE AddContract
GO

CREATE PROCEDURE AddContract
	@start date,
	@end date,
	@salary int,
	@team int,
	@cyclist int
	AS
	BEGIN
		SET NOCOUNT ON	

		IF (@start IS NULL) RAISERROR('Contract start date cannot be NULL!', 10, 1)
		IF (@end IS NULL) RAISERROR('Contract end date cannot be NULL!', 10, 1)
		-- check that the contract starts before its end, so that the duration is 1 day and longer
		IF (@start >= @end) RAISERROR('Contract start must be before its end!', 10, 1)

		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO [contract] (contract_start, contract_end, salary, team_id, cyclist_id)
				VALUES (@start, @end, @salary, @team, @cyclist);
			COMMIT TRANSACTION
			PRINT 'A new contract was successfully added.'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error while inserting a new contract.'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('ChangeContractDuration', 'P') IS NOT NULL DROP PROCEDURE ChangeContractDuration
GO

CREATE PROCEDURE ChangeContractDuration
	@contractId int, 
	@newStart date,
	@newEnd date
	AS
	BEGIN
		SET NOCOUNT ON	
		
		IF (@newStart >= @newEnd) RAISERROR('A contract has to last at least 1 day!', 10, 1)
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE contract
			SET contract_start = @newStart, contract_end = @newEnd
			WHERE id = @contractId;
			COMMIT TRANSACTION
			PRINT 'The duration of a contract was successfully changed.'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error while editing the duraiton of a contract!'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('RenameTeam', 'P') IS NOT NULL DROP PROCEDURE RenameTeam
GO

CREATE PROCEDURE RenameTeam
	@teamId int,
	@newName varchar(255)
	AS
	BEGIN
		SET NOCOUNT ON	
		IF (@newName IS NULL) RAISERROR('A new team name cannot be null!', 10, 1)
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE Team
			SET team_name = @newName
			WHERE id = @teamId;
			COMMIT TRANSACTION
			PRINT 'A team''s name was successfully changed!'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error while changing a team''s name!'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('AddStartList', 'P') IS NOT NULL DROP PROCEDURE AddStartList
GO

CREATE PROCEDURE AddStartList
	@startList XML,
	@raceId int
	AS
	BEGIN
		SET NOCOUNT ON	
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO start_list	(start_number, race_id, cyclist_id)
				SELECT 
					start_number = @startList.value('(/sl/entry/number)[1]', 'int'),
					race_id = @raceId,
					cyclist_id = @startList.value('(/sl/entry/id)[1]', 'int')

			COMMIT TRANSACTION
			PRINT 'A new start list was successfully inserted!'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error while adding a new start list! XML shall be formatted as <sl><entry><number>XXX</number><id>XXX</id></entry>...</sl>'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('DeleteRace', 'P') IS NOT NULL DROP PROCEDURE DeleteRace
GO

CREATE PROCEDURE DeleteRace
	@id int
	AS
	BEGIN
		SET NOCOUNT ON	
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM race WHERE id = @id;
			COMMIT TRANSACTION
			PRINT 'A race was successfully deleted!'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error while deleting a race. The race was not deleted.'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO

if OBJECT_ID('ReplaceRiderOnStartList', 'P') IS NOT NULL DROP PROCEDURE ReplaceRiderOnStartList
GO

CREATE PROCEDURE ReplaceRiderOnStartList
	@oldCyclistId int,
	@raceId int,
	@newCyclistId int
	AS
	BEGIN
		SET NOCOUNT ON	
		-- check if this record exists and not, throw an error
		IF NOT EXISTS (SELECT * FROM start_list AS sl WHERE sl.cyclist_id = @oldCyclistId AND sl.race_id = @raceId) RAISERROR('Unable to replace a rider on the start list, because this record does not exist!', 10, 1)
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE start_list SET cyclist_id = @newCyclistId WHERE race_id = @raceId AND cyclist_id = @oldCyclistId
			COMMIT TRANSACTION
			PRINT 'A start list was successfully edited!'
		END TRY 
		BEGIN CATCH 
			ROLLBACK TRANSACTION
			PRINT 'Error while altering start list!'
			PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER(), 1) + ': '+ ERROR_MESSAGE()
		END CATCH
	END
GO
