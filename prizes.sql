
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS prize_prizes;
SET FOREIGN_KEY_CHECKS=1;


CREATE TABLE IF NOT EXISTS prize_prizes (
	arena VARCHAR(16) CHARACTER SET latin1 NOT NULL,
    name VARCHAR(24) CHARACTER SET latin1 NOT NULL,
    cost FLOAT8 NOT NULL,
    description VARCHAR(256) DEFAULT NULL,
    data VARCHAR(256) DEFAULT '' NOT NULL,
    INDEX(arena),
    INDEX(name),
    PRIMARY KEY (arena, name)
);


DROP PROCEDURE IF EXISTS Prize_GetPrizes;
DROP PROCEDURE IF EXISTS Prize_CreatePrize;
DROP PROCEDURE IF EXISTS Prize_DeletePrize;

DELIMITER $$

CREATE PROCEDURE Prize_GetPrizes(
	arena VARCHAR(24) CHARACTER SET latin1
) COMMENT 'Show the name, cost, description, and date for prizes available in the given arena'
BEGIN
	SELECT name, cost, description, data FROM prize_prizes WHERE prize_prizes.arena = arena ORDER BY name ASC;
END$$

CREATE PROCEDURE Prize_CreatePrize(
	arena VARCHAR(16) CHARACTER SET latin1,
    name VARCHAR(24) CHARACTER SET latin1,
    cost FLOAT8,
    description VARCHAR(256),
    data VARCHAR(256)
) COMMENT 'Create a prize available for purchase in a specific arena'
CurrentSP:BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SELECT FALSE; END;
	INSERT INTO prize_prizes (arena, name, cost, description, data) VALUES (arena, name, cost, description, data);
	IF ROW_COUNT() > 0 THEN
		SELECT TRUE;
	ELSE
		SELECT FALSE;
	END IF;
END$$

CREATE PROCEDURE Prize_DeletePrize(
	arena VARCHAR(16) CHARACTER SET latin1,
    name VARCHAR(24) CHARACTER SET latin1
) COMMENT 'Delete a prize in the given arena'
CurrentSP:BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SELECT FALSE; END;
	DELETE FROM prize_prizes WHERE (prize_prizes.arena, prize_prizes.name) = (arena, name);
    IF ROW_COUNT() > 0 THEN
		SELECT TRUE;
	ELSE
		SELECT FALSE;
	END IF;
END$$

DELIMITER ;

