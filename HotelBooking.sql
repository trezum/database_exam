-------------------------------
-------------------------------
-- Databaser for udviklere   --
-- Eksamensopgave            --
-- Lars Søndergaard Petersen --
-------------------------------
-------------------------------

USE hotelbooking

--Dropping tables
DROP TABLE IF EXISTS Booking
DROP TABLE IF EXISTS BookingHelper
DROP TABLE IF EXISTS CompanyCustomer
DROP TABLE IF EXISTS Price
DROP TABLE IF EXISTS ConferenceRoom
DROP TABLE IF EXISTS Hotel

--Dropping UDFs
DROP FUNCTION IF EXISTS booking_check_hotel_conferenceroom
DROP FUNCTION IF EXISTS booking_check_no_weekend
DROP FUNCTION IF EXISTS smallest_available_conference_room

--Dropping stored procedures 
DROP PROC IF EXISTS booking_price_calculator_procedure

--Dropping Triggers
DROP TRIGGER IF EXISTS no_new_prices_in_the_past_trigger

--Creating UDFs to be used in constraints
GO
CREATE FUNCTION booking_check_hotel_conferenceroom(@HotelId INT, @ConferenceRoomId INT)
RETURNS BIT
AS
BEGIN
IF (SELECT HotelId FROM ConferenceRoom WHERE Id = @ConferenceRoomId) = @HotelId
	RETURN 1
RETURN 0
END;
GO

CREATE FUNCTION booking_check_no_weekend(@StartDate DATE, @Days INT)
RETURNS BIT
AS
BEGIN
-- Because of the constraint on bookings not being able to be more than 5 days we dont need to check for that here.
-- søn = 1 -- man = 2 -- tir = 3 -- ons = 4-- tor = 5-- fre = 6-- lør = 7
--Checking if any of  the end dates are weekend days.
IF DATEPART(DW, @StartDate) = 1 OR DATEPART(DW, @StartDate) = 7
	RETURN 0
ELSE IF DATEPART(DW, DATEADD(DD, @Days-1, @StartDate)) = 1 OR DATEPART(DW, DATEADD(DD, @Days-1, @StartDate)) = 7
	RETURN 0
-- Checking if we passed the weekend.
ELSE IF DATEPART(DW, @StartDate) > DATEPART(DW, DATEADD(DD, @Days-1, @StartDate))
	RETURN 0
RETURN 1
END;
GO

--Creating tables
CREATE TABLE CompanyCustomer
(
	Id INT IDENTITY PRIMARY KEY,
	Name VARCHAR(50) NOT NULL UNIQUE,
	Discount DECIMAL(5,3) NOT NULL,
)

CREATE TABLE Hotel
(
	Id INT IDENTITY PRIMARY KEY,	
	Name VARCHAR(50) NOT NULL UNIQUE,
	Rooms INT NOT NULL,
)

CREATE TABLE ConferenceRoom
(
	Id INT IDENTITY PRIMARY KEY,
	HotelId INT NOT NULL FOREIGN KEY REFERENCES Hotel,
	Name VARCHAR(50) NOT NULL,
	Capacity INT NOT NULL,
)

CREATE TABLE BookingHelper
(
	HotelId INT NOT NULL FOREIGN KEY REFERENCES Hotel,
	FreeRooms INT NOT NULL CHECK(FreeRooms >= 0),
	Date DATE NOT NULL,	
	PRIMARY KEY (HotelId, Date)
)

CREATE TABLE Price
(
	Id INT IDENTITY PRIMARY KEY,
	HotelId INT NOT NULL FOREIGN KEY REFERENCES Hotel,
	Price DECIMAL(18,3) NOT NULL,
	ActiveFrom DATE NOT NULL,	
)

CREATE TABLE Booking
(
	Id INT IDENTITY PRIMARY KEY,
	HotelId INT NOT NULL FOREIGN KEY REFERENCES Hotel,
	ConferenceRoomId INT NOT NULL FOREIGN KEY REFERENCES ConferenceRoom ,
	CompanyCustomerId INT NOT NULL FOREIGN KEY REFERENCES CompanyCustomer,	
	Participants INT NOT NULL,
	StartDate DATE NOT NULL,
	Days INT NOT NULL CHECK(Days IN (2,3,4,5)),

	CONSTRAINT booking_check_hotel_conferenceroom_constraint 
	CHECK( 1 = dbo.booking_check_hotel_conferenceroom(HotelId, ConferenceRoomId)),

	CONSTRAINT booking_check_no_weekend_constraint 
	CHECK( 1 = dbo.booking_check_no_weekend(StartDate, Days)),
)

--Inserting test data
INSERT INTO CompanyCustomer VALUES ('Elgiganten',12), ('Bilka',10), ('Coop',15), ('Ikea',30), ('Google',50)
INSERT INTO Hotel VALUES ('Danhostel', 543), ('Guldsmeden',80), ('Zleep',90), ('Ritz',123), ('Comwell',230)
INSERT INTO ConferenceRoom (HotelId, Name, Capacity) VALUES (1,'Room D50',50 ), ( 1,'Room D25',25 ), ( 1,'Room D10',10 ), ( 1,'Room D5a',5 ), ( 1,'Room D5b',5 )
INSERT INTO ConferenceRoom (HotelId, Name, Capacity) VALUES (2,'Room G50',50 ), ( 2,'Room G25',25 ), ( 2,'Room G10',10 ), ( 2,'Room G5a',5 ), ( 2,'Room G5b',5 )
INSERT INTO ConferenceRoom (HotelId, Name, Capacity) VALUES (3,'Room Z50',50 ), ( 3,'Room Z25',25 ), ( 3,'Room Z10',10 ), ( 3,'Room Z5a',5 ), ( 3,'Room Z5b',5 )
INSERT INTO ConferenceRoom (HotelId, Name, Capacity) VALUES (4,'Room R50',50 ), ( 4,'Room R25',25 ), ( 4,'Room R10',10 ), ( 4,'Room R5a',5 ), ( 4,'Room R5b',5 )
INSERT INTO ConferenceRoom (HotelId, Name, Capacity) VALUES (5,'Room C50',50 ), ( 5,'Room C25',25 ), ( 5,'Room C10',10 ), ( 5,'Room C5a',5 ), ( 5,'Room C5b',5 )
INSERT INTO Price (HotelId, Price, ActiveFrom) VALUES (1,101,'2020-05-10'), (2,102,'2020-05-10'), (3,103,'2020-05-10'), (4,104,'2020-05-10'), (5,105,'2020-05-10')
INSERT INTO Price (HotelId, Price, ActiveFrom) VALUES (1,201,'2020-05-25'), (2,202,'2020-05-25'), (3,203,'2020-05-25'), (4,204,'2020-05-25'), (5,205,'2020-05-25')
INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (2, 6, 1, 45, '2020-05-18', 4), (2, 7, 1, 20, '2020-05-18', 3), (2, 8, 1, 9, '2020-05-18', 2)
INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (2, 6, 1, 45, '2020-05-27', 3), (2, 7, 1, 20, '2020-05-27', 3), (2, 8, 1, 9, '2020-05-27', 2)
INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (2, 6, 1, 45, '2020-06-10', 3), (2, 7, 1, 20, '2020-06-10', 3), (2, 8, 1, 9, '2020-06-10', 2)
INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (2, 6, 1, 45, '2020-06-17', 3), (2, 7, 1, 20, '2020-06-17', 3), (2, 8, 1, 9, '2020-06-17', 2)
INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (3, 12, 1, 45, '2020-05-27', 3), (3, 13, 1, 20, '2020-05-27', 3), (3, 14, 1, 9, '2020-05-27', 2)
INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (3, 12, 1, 45, '2020-06-10', 3), (3, 13, 1, 20, '2020-06-10', 3), (3, 14, 1, 9, '2020-06-10', 2)
INSERT INTO BookingHelper VALUES (2,6,'2020-05-18'), (2,6,'2020-05-19'), (2,26,'2020-05-20'), (2,35,'2020-05-21')
GO

--Use to test the contraint on booking ( booking_check_hotel_conferenceroom )
--INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (1, 6, 1, 45, '2020-05-20', 4)

--Use to test the contraint on booking ( booking_check_no_weekend )
--INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (1, 6, 1, 45, '2020-05-25', 2)
--INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (1, 6, 1, 45, '2020-05-23', 5)

--Trigger for making sure no prices are inserted for past data


GO
CREATE TRIGGER no_new_prices_in_the_past_trigger
ON Price
AFTER INSERT, UPDATE, DELETE
AS
IF EXISTS (SELECT * FROM inserted WHERE ActiveFrom < GETDATE())
BEGIN 
	ROLLBACK TRAN
	RAISERROR('No price changes in the past.',16,1)
END

IF EXISTS (SELECT * FROM deleted WHERE ActiveFrom < GETDATE())
BEGIN 
	ROLLBACK TRAN
	RAISERROR('Past prices can not be deleted.',16,1)
END
GO

--For testing price no_new_prices_in_the_past_trigger
--INSERT INTO Price (HotelId, Price, ActiveFrom) VALUES (1,200,'2029-05-25')
--INSERT INTO Price (HotelId, Price, ActiveFrom) VALUES (1,200,'2019-05-25')
--DELETE FROM Price
--UPDATE Price SET ActiveFrom = GETDATE()

--Creating the three most relevant indexes
CREATE UNIQUE INDEX Price_HotelId_ActiveFrom_Index ON Price (HotelId, ActiveFrom)
CREATE INDEX ConferenceRoom_HotelId_Capacity_Index ON ConferenceRoom (HotelId, Capacity)
CREATE INDEX Booking_CompanyCustomerId_Index ON Booking (CompanyCustomerId)
--Trigger for updating the redundant table BookingHelper, when a booking is inserted.
--This is made to only handle single inserts of bookings.
GO
CREATE TRIGGER booking_helper_trigger
ON Booking
AFTER INSERT
AS

DECLARE @HotelId INT
DECLARE @DaysToAdd INT
DECLARE @Participants INT
DECLARE @HotelRooms INT
DECLARE @StartDate DATE
DECLARE @EndDate DATE

SELECT @HotelId = HotelId FROM inserted
SELECT @DaysToAdd = (Days-1) FROM inserted
SELECT @Participants = Participants FROM inserted
SELECT @HotelRooms = Rooms FROM Hotel WHERE Id = @HotelId
SELECT @StartDate = StartDate FROM inserted
SELECT @EndDate =  DATEADD(DD, @DaysToAdd, @StartDate) FROM inserted; -- Semicolon needed before cte

--Inserting missing dates
--I went a bit overboard trying not to use a cursor here.
--Creating a cte containing the required dates.
WITH cte AS (
	SELECT 
		b.HotelId, 
		b.StartDate,
		(SELECT Rooms FROM Hotel WHERE Id = b.HotelId) AS Rooms,
		b.Days, 
		1 AS START
	FROM inserted b

	UNION ALL

	SELECT 
		c.HotelId, 
		DATEADD(DD, 1, c.StartDate), 
		(SELECT Rooms FROM Hotel WHERE Id = c.HotelId) AS Rooms,
		c.Days, 
		START + 1

	FROM cte c
	WHERE START < c.Days
)

INSERT INTO BookingHelper (HotelId, FreeRooms, Date) 
	--Excepting the cte with the existing dates to find the missing ones.
	--Adding the needed hotel rooms to only compare date and hotelid, 
	--while prepping for insert if needed.
	SELECT HotelId, @HotelRooms AS FreeRooms, StartDate AS Date 
	FROM cte 

	EXCEPT

	SELECT HotelId, @HotelRooms AS FreeRooms, Date 
	FROM BookingHelper 
	WHERE HotelId = @HotelId AND (@StartDate <= Date AND @EndDate >= Date)

--Updating dates to decrease by the number of participants
--Fails when going below 0 becaus of the constraint on FreeRooms, thereby failing the booking insert.
UPDATE BookingHelper 
SET FreeRooms = (FreeRooms - @Participants)
WHERE HotelId = @HotelId AND (@StartDate <= Date AND @EndDate >= Date)

GO
--For testing the BookingHelper trigger
--INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) VALUES (5, 21, 1, 10, '2020-05-18', 5)

--Creating stored proceadure to calculate the price of a booking with discount.
CREATE PROC booking_price_calculator_procedure (@BookingId INT, @BookingPrice DECIMAL(18,3) OUTPUT)
AS
	SELECT TOP 1 @BookingPrice =  b.Participants*b.Days*p.Price*((100-cc.Discount)/100)
	FROM Booking b
	INNER JOIN CompanyCustomer cc
	ON cc.Id = b.CompanyCustomerId
	INNER JOIN Price p
	ON p.HotelId = b.HotelId
	WHERE b.Id = @BookingId AND ActiveFrom >= b.StartDate
	ORDER BY ActiveFrom
GO

--For testing the store proceadure
--DECLARE @BookingId INT
--DECLARE @BookingPrice DECIMAL(18,3)
--SELECT @BookingId = 1
--EXEC booking_price_calculator_procedure  @BookingId, @BookingPrice OUTPUT
--PRINT @BookingPrice

GO
--Creating function to figure out what the smallest available 
--conference room is for given parmeters ( parameters for making a booking ).
CREATE FUNCTION smallest_available_conference_room(@HotelId INT, @StartDate DATE, @Days INT, @Participants INT)
RETURNS INT
AS
BEGIN
DECLARE @Result INT;

--Finding booked date-room combinations using CTE 
WITH cte AS 
(
	SELECT 1 AS START,b.Id, b.StartDate AS BookedDate, b.HotelId, ConferenceRoomId , Days
	FROM Booking b
	WHERE b.HotelId = @HotelId
	UNION ALL
	SELECT START + 1,c.Id, DATEADD(DD, 1, c.BookedDate) AS BookedDate , c.HotelId, ConferenceRoomId , Days
	FROM cte c	
	WHERE START < c.Days AND HotelId = @HotelId
)

--Selcting the lowest capacity room that fits the requirements
SELECT TOP (1) @Result = Id FROM ConferenceRoom
WHERE Id NOT IN 
(
	--Selecting rooms within the duration that can't be used
	SELECT DISTINCT ConferenceRoomId FROM cte
	--This where could potentially be moved into the cte to improve performance and lock less.
	WHERE BookedDate >= @StartDate AND BookedDate <= DATEADD(DD, @Days-1, @StartDate)
) AND
Capacity >= @Participants AND
Hotelid = @HotelId 
ORDER BY Capacity ASC

RETURN @Result
END
GO

-- For testing the UDF smallest_available_conference_room
--DECLARE @Result INT
--EXEC @Result = smallest_available_conference_room 2, '2020-05-18', 3, 30
--SELECT @Result