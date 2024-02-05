-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: rdbms.strato.de
-- Erstellungszeit: 05. Feb 2024 um 23:16
-- Server-Version: 8.0.32
-- PHP-Version: 8.1.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Datenbank: `dbs12522801`
--
CREATE DATABASE IF NOT EXISTS `dbs12522801` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `dbs12522801`;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `Borrowers`
--

CREATE TABLE `Borrowers` (
  `ID` int NOT NULL,
  `LendingCount` int DEFAULT NULL,
  `Firstname` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Lastname` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Role` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Email` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `CourseOfStudy` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Telephone` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `StudyID` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `Inventory`
--

CREATE TABLE `Inventory` (
  `ID` int NOT NULL,
  `Device` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Category` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `SerialNo` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `InventoryNo` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Purchased` date DEFAULT NULL,
  `CurrentLocation` int DEFAULT NULL,
  `Borrower` int DEFAULT NULL,
  `Lender` int DEFAULT NULL,
  `BelongsTo` int DEFAULT NULL,
  `PlannedReturnDate` date DEFAULT NULL,
  `Status` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `DeviceCondition` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `LatestComment` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `InventoryListed` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `Lenders`
--

CREATE TABLE `Lenders` (
  `ID` int NOT NULL,
  `LendingCount` int DEFAULT NULL,
  `Firstname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Lastname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Email` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Telephone` varchar(15) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Role` enum('Professor','Staff','HiWi','Other') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `Lendings`
--

CREATE TABLE `Lendings` (
  `ID` int NOT NULL,
  `EnteringDate` date DEFAULT NULL,
  `Borrower` int DEFAULT NULL,
  `Module` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Lender` int DEFAULT NULL,
  `Device` int DEFAULT NULL,
  `CurrentLocation` int DEFAULT NULL,
  `LendingDate` date DEFAULT NULL,
  `PlannedReturnDate` date DEFAULT NULL,
  `ReturnDate` date DEFAULT NULL,
  `Status` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `DeviceCondition` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `Comment` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Trigger `Lendings`
--
DELIMITER $$
CREATE TRIGGER `set_device_available_on_delete` AFTER DELETE ON `Lendings` FOR EACH ROW BEGIN
    UPDATE Inventory
    SET Status = 'available'
    WHERE ID = OLD.Device;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_inventory_borrowerandlender_on_lending_update` AFTER UPDATE ON `Lendings` FOR EACH ROW BEGIN
	UPDATE Borrowers SET LendingCount = (SELECT COUNT(*) FROM Lendings WHERE Borrower = NEW.Borrower AND Status != 'filed') WHERE ID = NEW.Borrower;
	UPDATE Lenders SET LendingCount = (SELECT COUNT(*) FROM Lendings WHERE Lender = NEW.Lender AND Status != 'filed') WHERE ID = NEW.Lender;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_inventory_on_lending_update` AFTER UPDATE ON `Lendings` FOR EACH ROW BEGIN
    IF NEW.Status = 'filed' THEN
        -- Set device as available, clear BorrowedBy, LentBy, and PlannedReturnDate
        UPDATE Inventory
        SET Status = 'available', Borrower = NULL, Lender = NULL, PlannedReturnDate = NULL
        WHERE ID = NEW.Device;
    ELSE
        -- Update the device status based on the lending status and set PlannedReturnDate accordingly
        UPDATE Inventory
        SET Status = NEW.Status, Borrower = NEW.Borrower, Lender = NEW.Lender,
            PlannedReturnDate = CASE WHEN NEW.Status = 'available' THEN NULL ELSE NEW.PlannedReturnDate END
        WHERE ID = NEW.Device;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_inventory_on_new_lending` AFTER INSERT ON `Lendings` FOR EACH ROW BEGIN
    UPDATE Inventory
    SET Borrower = NEW.Borrower, Lender = NEW.Lender
    WHERE ID = NEW.Device;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_inventory_status_on_insert` AFTER INSERT ON `Lendings` FOR EACH ROW BEGIN
    IF NEW.Status = 'filed' THEN
        UPDATE Inventory
        SET Status = 'available'
        WHERE ID = NEW.Device;
    ELSE
        UPDATE Inventory
        SET Status = NEW.Status
        WHERE ID = NEW.Device;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stellvertreter-Struktur des Views `LendingSummary`
-- (Siehe unten für die tatsächliche Ansicht)
--
CREATE TABLE `LendingSummary` (
);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `Locations`
--

CREATE TABLE `Locations` (
  `ID` int NOT NULL,
  `Location` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur des Views `LendingSummary`
--
DROP TABLE IF EXISTS `LendingSummary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`o12522801`@`%` SQL SECURITY DEFINER VIEW `LendingSummary`  AS SELECT `ld`.`EnteringDate` AS `EnteringDate`, `b`.`Firstname` AS `BorrowerFirstname`, `b`.`Lastname` AS `BorrowerLastname`, `b`.`Email` AS `BorrowerEmail`, `i`.`Device` AS `Device`, `i`.`Category` AS `Category`, `loc`.`Location` AS `CurrentLocation`, `ld`.`LendingDate` AS `LendingDate`, `ld`.`ExtendedDate` AS `ExtendedDate`, `ld`.`ReturnDate` AS `ReturnDate`, `l`.`Firstname` AS `LenderFirstname`, `l`.`Lastname` AS `LenderLastname`, `l`.`Email` AS `LenderEmail`, (case when (`ld`.`ReturnDate` < curdate()) then 'true' else 'false' end) AS `Overdue` FROM ((((`Lendings` `ld` join `Borrowers` `b` on((`ld`.`BorrowerID` = `b`.`ID`))) join `Lenders` `l` on((`ld`.`LenderID` = `l`.`ID`))) join `Inventory` `i` on((`ld`.`DeviceID` = `i`.`ID`))) join `Locations` `loc` on((`ld`.`CurrentLocationID` = `loc`.`ID`))) ;

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `Borrowers`
--
ALTER TABLE `Borrowers`
  ADD PRIMARY KEY (`ID`);

--
-- Indizes für die Tabelle `Inventory`
--
ALTER TABLE `Inventory`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `Inventory_ibfk_1` (`CurrentLocation`),
  ADD KEY `Inventory_ibfk_2` (`BelongsTo`),
  ADD KEY `Inventory_ibfk_4` (`Lender`),
  ADD KEY `Inventory_ibfk_3` (`Borrower`);

--
-- Indizes für die Tabelle `Lenders`
--
ALTER TABLE `Lenders`
  ADD PRIMARY KEY (`ID`);

--
-- Indizes für die Tabelle `Lendings`
--
ALTER TABLE `Lendings`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `Lendings_ibfk_1` (`Borrower`),
  ADD KEY `Lendings_ibfk_2` (`Lender`),
  ADD KEY `Lendings_ibfk_3` (`Device`),
  ADD KEY `Lendings_ibfk_4` (`CurrentLocation`);

--
-- Indizes für die Tabelle `Locations`
--
ALTER TABLE `Locations`
  ADD PRIMARY KEY (`ID`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `Lendings`
--
ALTER TABLE `Lendings`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT;

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `Inventory`
--
ALTER TABLE `Inventory`
  ADD CONSTRAINT `Inventory_ibfk_1` FOREIGN KEY (`CurrentLocation`) REFERENCES `Locations` (`ID`) ON DELETE SET NULL ON UPDATE RESTRICT,
  ADD CONSTRAINT `Inventory_ibfk_2` FOREIGN KEY (`BelongsTo`) REFERENCES `Locations` (`ID`) ON DELETE SET NULL ON UPDATE RESTRICT,
  ADD CONSTRAINT `Inventory_ibfk_3` FOREIGN KEY (`Borrower`) REFERENCES `Borrowers` (`ID`) ON DELETE SET NULL ON UPDATE RESTRICT,
  ADD CONSTRAINT `Inventory_ibfk_4` FOREIGN KEY (`Lender`) REFERENCES `Lenders` (`ID`) ON DELETE SET NULL ON UPDATE RESTRICT;

--
-- Constraints der Tabelle `Lendings`
--
ALTER TABLE `Lendings`
  ADD CONSTRAINT `Lendings_ibfk_1` FOREIGN KEY (`Borrower`) REFERENCES `Borrowers` (`ID`) ON DELETE SET NULL ON UPDATE RESTRICT,
  ADD CONSTRAINT `Lendings_ibfk_2` FOREIGN KEY (`Lender`) REFERENCES `Lenders` (`ID`) ON DELETE SET NULL ON UPDATE RESTRICT,
  ADD CONSTRAINT `Lendings_ibfk_3` FOREIGN KEY (`Device`) REFERENCES `Inventory` (`ID`) ON DELETE SET NULL ON UPDATE RESTRICT,
  ADD CONSTRAINT `Lendings_ibfk_4` FOREIGN KEY (`CurrentLocation`) REFERENCES `Locations` (`ID`) ON DELETE SET NULL ON UPDATE RESTRICT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
