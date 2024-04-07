CREATE DATABASE “AnsonBase”;
GO

USE "AnsonBase";

CREATE TABLE Person (
    PersonID INT PRIMARY KEY,
    LastName VARCHAR(255),
    FirstName VARCHAR(255),
    DateOfBirth DATE
);

-- Create the Specialty table
CREATE TABLE Specialty (
    SpecialtyID INT PRIMARY KEY,
    Name VARCHAR(255),
    Description TEXT
);

-- Create the Organization table
CREATE TABLE Organization (
    OrganizationID INT PRIMARY KEY,
    Name VARCHAR(255),
    MainPhone VARCHAR(20)
);

-- Create the Volunteering table
CREATE TABLE Volunteering (
    VolunteeringID INT PRIMARY KEY,
    PersonID INT,
    OrganizationID INT,
    SpecialtyID INT,
    FOREIGN KEY (PersonID) REFERENCES Person(PersonID),
    FOREIGN KEY (OrganizationID) REFERENCES Organization(OrganizationID),
    FOREIGN KEY (SpecialtyID) REFERENCES Specialty(SpecialtyID)
);