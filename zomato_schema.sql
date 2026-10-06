CREATE TABLE restaurants (
    `Restaurant ID` BIGINT,
    `Restaurant Name` VARCHAR(255),
    `Country Code` BIGINT,
    `City` VARCHAR(255),
    `Address` TEXT,
    `Locality` VARCHAR(255),
    `Locality Verbose` TEXT,
    `Longitude` DOUBLE,
    `Latitude` DOUBLE,
    `Cuisines` TEXT,
    `Average Cost for two` BIGINT,
    `Currency` VARCHAR(255),
    `Has Table booking` VARCHAR(255),
    `Has Online delivery` VARCHAR(255),
    `Is delivering now` VARCHAR(255),
    `Switch to order menu` VARCHAR(255),
    `Price range` BIGINT,
    `Aggregate rating` DOUBLE,
    `Rating color` VARCHAR(255),
    `Rating text` VARCHAR(255),
    `Votes` BIGINT
) DEFAULT CHARACTER SET utf8mb4;

CREATE TABLE country_codes (
    `Country Code` BIGINT,
    `Country` VARCHAR(255)
) DEFAULT CHARACTER SET utf8mb4;
