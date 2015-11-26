
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS egc_balances;
DROP TABLE IF EXISTS egc_transactions;
DROP TABLE IF EXISTS egc_accounts;
DROP TABLE IF EXISTS egc_config_ints;
SET FOREIGN_KEY_CHECKS=1;


CREATE TABLE IF NOT EXISTS egc_config_ints (
	k VARCHAR(128) NOT NULL PRIMARY KEY,
    v INTEGER UNSIGNED
);

CREATE TABLE IF NOT EXISTS egc_accounts (
	id INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(24) CHARACTER SET latin1 NOT NULL UNIQUE KEY
);

CREATE TABLE IF NOT EXISTS egc_balances (
	account_id INTEGER UNSIGNED,
    balance FLOAT8,
    FOREIGN KEY (account_id) REFERENCES egc_accounts(id),
    INDEX (balance)
);

CREATE TABLE IF NOT EXISTS egc_transactions (
	id INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    timestamp DATETIME,
    account_id1 INTEGER UNSIGNED,
    account_id2 INTEGER UNSIGNED,
    type ENUM('add', 'remove', 'transfer', 'set'),
    value FLOAT8,
    comment VARCHAR(128),
    FOREIGN KEY (account_id1) REFERENCES egc_accounts(id),
    -- FOREIGN KEY (account_id2) REFERENCES egc_accounts(id),   -- commented out because target account can be null 
	INDEX(timestamp)
);


DROP PROCEDURE IF EXISTS Egc_AccountCreate;
DROP FUNCTION  IF EXISTS Egc_AccountId;
DROP PROCEDURE IF EXISTS Egc_Add;
DROP PROCEDURE IF EXISTS Egc_Balance;
DROP PROCEDURE IF EXISTS Egc_SetBalance;
DROP PROCEDURE IF EXISTS Egc_Remove;
DROP PROCEDURE IF EXISTS Egc_Log;
DROP PROCEDURE IF EXISTS Egc_Transfer;

DROP FUNCTION  IF EXISTS EgcConfig_GetInt;
DROP FUNCTION  IF EXISTS EgcConfig_SetInt;


DELIMITER $$

CREATE PROCEDURE Egc_AccountCreate(
	NAME VARCHAR(24) CHARACTER SET latin1
) 
BEGIN
	-- DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SELECT FALSE; END;
	INSERT INTO egc_accounts (id, name) VALUES (NULL, name);
    INSERT INTO egc_balances (account_id, balance) VALUES (LAST_INSERT_ID(), 0.0);
    SELECT TRUE;
END$$


CREATE FUNCTION Egc_AccountId(
	NAME VARCHAR(24) CHARACTER SET latin1
) RETURNS INTEGER UNSIGNED
BEGIN
	SET @result = NULL;
	IF EXISTS(SELECT id FROM egc_accounts WHERE egc_accounts.name = name) THEN
		SELECT id INTO @result FROM egc_accounts WHERE egc_accounts.name = name;
	END IF;
    RETURN @result;
END$$


CREATE FUNCTION EgcConfig_GetInt(
	k VARCHAR(128) CHARACTER SET latin1
) RETURNS INTEGER UNSIGNED
BEGIN
	SET @result = NULL;
	SELECT v INTO @result FROM egc_config_ints WHERE egc_config_ints.k = k;
    RETURN @result;
END$$

CREATE FUNCTION EgcConfig_SetInt(
	k VARCHAR(128) CHARACTER SET latin1,
    v INTEGER UNSIGNED
) RETURNS INTEGER UNSIGNED
BEGIN
	REPLACE INTO egc_config_ints (k, v) VALUES (k, v);
    RETURN v;
END$$


CREATE PROCEDURE Egc_Balance(
	name VARCHAR(24) CHARACTER SET latin1
)
BEGIN
	SET @result = NULL;
	IF EXISTS(SELECT id FROM egc_accounts WHERE egc_accounts.name = name) THEN
		SELECT balance INTO @result FROM egc_balances INNER JOIN egc_accounts ON account_id = id WHERE egc_accounts.name = name;
	END IF;
    SELECT @result;
END$$


CREATE PROCEDURE Egc_Add(
	name VARCHAR(24) CHARACTER SET latin1,
    value FLOAT8,
    comment VARCHAR(256)
) COMMENT 'Adds EGC to a players account'
CurrentSP:BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SELECT FALSE; END;
	IF value < 0.0 THEN SELECT FALSE; LEAVE CurrentSP; END IF;
    
	IF NOT EXISTS(SELECT id FROM egc_accounts WHERE egc_accounts.name = name) THEN
		CALL Egc_AccountCreate(name);
	END IF;
    
    SET @max = EgcConfig_GetInt('MaxEgc');
    
	UPDATE egc_balances INNER JOIN egc_accounts ON account_id = id SET balance = balance + value WHERE egc_accounts.name = name AND balance + value <= @max;
    
    IF ROW_COUNT() > 0 THEN
		CALL Egc_Log(name, NULL,  'add', value, comment);
		SELECT TRUE;
	ELSE
		SELECT FALSE;
	END IF;
END$$


CREATE PROCEDURE Egc_Remove(
	name VARCHAR(24) CHARACTER SET latin1,
    value FLOAT8,
    comment VARCHAR(256)
) COMMENT 'Adds EGC to a players account'
CurrentSP:BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SELECT FALSE; END;
	IF value < 0.0 THEN SELECT FALSE; LEAVE CurrentSP; END IF;
    
	IF NOT EXISTS(SELECT id FROM egc_accounts WHERE egc_accounts.name = name) THEN
		CALL Egc_AccountCreate(name);
	END IF;
    
    IF EXISTS(SELECT 1 FROM egc_balances INNER JOIN egc_accounts ON account_id = id WHERE egc_accounts.name = name AND balance >= value) THEN
		UPDATE egc_balances INNER JOIN egc_accounts ON account_id = id SET balance = balance - value WHERE egc_accounts.name = name;
        CALL Egc_Log(name, NULL,  'remove', value, comment);
        SELECT TRUE;
	ELSE
		SELECT FALSE;
    END IF;
END$$


CREATE PROCEDURE Egc_Transfer(
	sender VARCHAR(24) CHARACTER SET latin1,
	recipient VARCHAR(24) CHARACTER SET latin1,
    value FLOAT8,
    comment VARCHAR(256)
) COMMENT 'Transfer EGC to a players account'
CurrentSP:BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SELECT FALSE; END;
	IF value <= 0.0 THEN SELECT FALSE; LEAVE CurrentSP; END IF;
    
    -- make sure sender and recipient are different
    SET @sender_id = Egc_AccountId(sender);
    SET @recipient_id = Egc_AccountId(recipient);
    IF @sender_id = @recipient_id OR @sender_id IS NULL OR @recipient_id IS NULL THEN SELECT FALSE; LEAVE CurrentSP; END IF;
    
    SET @max = EgcConfig_GetInt('MaxEgc');
    
    IF EXISTS(SELECT 1 FROM egc_balances INNER JOIN egc_accounts ON account_id = id WHERE egc_accounts.id = @sender_id AND balance >= value) AND
       EXISTS(SELECT 1 FROM egc_balances INNER JOIN egc_accounts ON account_id = id WHERE egc_accounts.id = @recipient_id AND balance + value <= @max)
    THEN
		UPDATE egc_balances INNER JOIN egc_accounts ON account_id = id SET balance = balance - value WHERE egc_accounts.id = @sender_id;
		UPDATE egc_balances INNER JOIN egc_accounts ON account_id = id SET balance = balance + value WHERE egc_accounts.id = @recipient_id;
		CALL Egc_Log(sender, recipient,  'transfer', value, comment);
        SELECT TRUE;
	ELSE
		SELECT FALSE;
    END IF;
END$$

DELIMITER $$
CREATE PROCEDURE Egc_SetBalance(
	name VARCHAR(24) CHARACTER SET latin1,
    value FLOAT8,
    comment VARCHAR(256)
)
    COMMENT 'Sets a players EGC account balance'
CurrentSP:BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SELECT FALSE; END;
	IF value < 0.0 THEN SELECT FALSE; LEAVE CurrentSP; END IF;
    
	IF NOT EXISTS(SELECT id FROM egc_accounts WHERE egc_accounts.name = name) THEN
		CALL Egc_AccountCreate(name);
	END IF;
    
    SET @max = EgcConfig_GetInt('MaxEgc');
    
    if value < @max THEN
		UPDATE egc_balances INNER JOIN egc_accounts ON account_id = id SET balance = value WHERE egc_accounts.name = name;
		CALL Egc_Log(name, NULL,  'set', value, comment);
        SELECT TRUE;
	ELSE
		SELECT FALSE;
	END IF;
END$$


CREATE PROCEDURE Egc_Log(
	name1 VARCHAR(24) CHARACTER SET latin1,
    name2 VARCHAR(24) CHARACTER SET latin1,
    type ENUM('add', 'remove', 'transfer', 'set'),
    value FLOAT8,
    comment VARCHAR(128)
) COMMENT 'Log an Egc transaction'
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; END;
	SELECT id INTO @id1 FROM egc_accounts WHERE name = name1;
	IF name2 IS NOT NULL THEN
		SELECT id INTO @id2 FROM egc_accounts WHERE name = name2;
	ELSE
		SELECT NULL INTO @id2;
	END IF;
	INSERT INTO egc_transactions (id, timestamp, account_id1, account_id2, type, value, comment) VALUES (NULL, NOW(), @id1, @id2, type, value, comment);
END$$


DELIMITER ;

-- Set default config values
SELECT EgcConfig_SetInt('MaxEgc', 100);

