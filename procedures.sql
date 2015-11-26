DROP PROCEDURE IF EXISTS Pub_CurrentJackpot;
DROP PROCEDURE IF EXISTS Pub_CurrentTopPoints;
DROP PROCEDURE IF EXISTS Pub_CurrentTopKills;
DROP PROCEDURE IF EXISTS Pub_DaysInGame;
DROP PROCEDURE IF EXISTS Pub_TopPoints;
DROP PROCEDURE IF EXISTS BaseDuel_TopElo;
DROP PROCEDURE IF EXISTS Duel_TopElo;

DELIMITER $$

CREATE PROCEDURE Pub_CurrentJackpot(
) COMMENT 'Gets the highest jackpot in pub'
BEGIN
	SELECT FORMAT(jackpot, 0) AS Jackpot FROM flag_games WHERE arena REGEXP '^[0-9]+$' ORDER BY id DESC LIMIT 1;
END$$

CREATE PROCEDURE Pub_CurrentTopKills(
	IN max INT UNSIGNED
) COMMENT 'Gets the highest kill count'
BEGIN
	IF max > 100 THEN SET max = 100; END IF;
	SELECT player.name as Name, wins as Kills
	FROM
		pub_stats INNER JOIN player
	ON
		pub_stats.player_id = player.id AND
		STRCMP(LEFT(player.name, 4),'Bot-') AND
		STRCMP(LEFT(player.name, 7),'DevBot-')
	ORDER BY
		pub_stats.wins
	DESC LIMIT max;
END$$

-- XXX: This procedure may be complete wrong
CREATE PROCEDURE Pub_CurrentTopPoints(
	IN max INT UNSIGNED
) COMMENT 'Gets the point leaders in pub'
BEGIN
	IF max > 100 THEN SET max = 100; END IF;
	SELECT player.name as Name, flag_points + kill_points as Points
	FROM pub_stats, player
	WHERE pub_stats.player_id = player.id
	ORDER BY points DESC
	LIMIT max;
END$$

CREATE PROCEDURE Duel_TopElo(
	IN max INT UNSIGNED
) COMMENT 'Gets the point leaders in pub'
BEGIN
	IF max > 100 THEN SET max = 100; END IF;
	SELECT name AS Name, elo AS Elo FROM duel_elo ORDER BY elo DESC LIMIT max;
END$$

CREATE PROCEDURE BaseDuel_TopElo(
	IN max INT UNSIGNED
) COMMENT 'Gets the point leaders in pub'
BEGIN
	IF max > 100 THEN SET max = 100; END IF;
	SELECT name AS Name, elo AS Elo FROM bd_elo ORDER BY elo DESC LIMIT max;
END$$

CREATE PROCEDURE Pub_TopPoints(
    date_start DATETIME,
    date_end DATETIME,
    IN max INT UNSIGNED
)  COMMENT 'Gets top players by total points'
BEGIN
	IF date_start IS NULL THEN SELECT end_time FROM reset ORDER BY id DESC LIMIT 1 INTO date_start; END IF;
	IF date_start IS NULL THEN SET date_start = '1970-01-01 00:00:01'; END IF;
	IF date_end IS NULL THEN SET date_end = '2038-01-19 03:14:07'; END IF;
	IF max > 100 THEN SET max = 100; END IF;
    
    SET @row_number := 0;
	SELECT *, (@row_number := @row_number + 1) AS Rank FROM (
	SELECT 
		player.name AS 'Player Name',
		MIN(flag_games.end_time) AS 'First Seen',
		MAX(flag_games.end_time) AS 'Last Seen',
		SUM(warbird_time + javelin_time + spider_time + leviathan_time + terrier_time + weasal_time + lancaster_time + shark_time) / (60.0 * 60 * 24) AS `Days In Game`,
		SUM(spectator_time) / (60.0 * 60 * 24) AS 'Days in Spec',
		SUM(flag_points + kill_points + total_kothpoints + IF(winning_freq = freq && here != 0, jackpot, 0)) AS 'Points',
		SUM(wins) AS 'Kills',
		SUM(losses) AS 'Deaths',
		SUM(teamkills) AS 'Teamkills',
		SUM(flags_dropped) AS 'Flags Dropped',
		SUM(attaches) AS 'Other Players Attached',
		SUM(attached_to) AS 'Attached To',
		SUM(total_greens) AS 'Total Greens',
		SUM(goals) AS 'Goals Scored',
		MAX(IF(winning_freq = freq, jackpot, 0)) AS 'Largest Jackpot Won',
		MAX(IF(winning_freq != freq, jackpot, 0)) AS 'Largest Jackpot Lost'
	FROM
		flag_stats
			INNER JOIN
		player ON player.id = flag_stats.player_id
			INNER JOIN
		flag_games ON flag_games.id = flag_stats.game_id
			INNER JOIN
		squad ON squad.id = flag_stats.squad_id
	WHERE
		zone = 'EG'
			AND arena REGEXP '^[0-9]+$'
			AND end_time BETWEEN date_start AND date_end
	GROUP BY player.id
    HAVING `Points` > 0
	ORDER BY `Points` DESC
	LIMIT max
    ) top_points;
END$$

CREATE PROCEDURE Pub_DaysInGame(
    date_start DATETIME,
    date_end DATETIME
)  COMMENT 'Gets the total days spent in game for a date range'
BEGIN
	IF date_start IS NULL THEN SELECT end_time FROM reset ORDER BY id DESC LIMIT 1 INTO date_start; END IF;
	IF date_start IS NULL THEN SET date_start = '1970-01-01 00:00:01'; END IF;
	IF date_end IS NULL THEN SET date_end = '2038-01-19 03:14:07'; END IF;
    
	SELECT 
		SUM(warbird_time + javelin_time + spider_time + leviathan_time + terrier_time + weasal_time + lancaster_time + shark_time) / (60.0 * 60 * 24) AS `Days In Game`
	FROM
		flag_stats
			INNER JOIN
		player ON player.id = flag_stats.player_id
			INNER JOIN
		flag_games ON flag_games.id = flag_stats.game_id
	WHERE
		end_time BETWEEN date_start AND date_end AND
		zone = 'EG' AND
        arena REGEXP '^[0-9]+$';
END$$

DELIMITER ;
