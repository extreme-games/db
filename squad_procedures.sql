
DROP PROCEDURE IF EXISTS Squad_Totals;
DROP PROCEDURE IF EXISTS Squad_Players;
DROP PROCEDURE IF EXISTS Squad_TopPoints;

DELIMITER $$

CREATE PROCEDURE Squad_Totals(
	IN name VARCHAR(24) CHARACTER SET latin1,
    date_start DATETIME,
    date_end DATETIME
)  COMMENT 'Gets the lifetime stats for a squad, ordered by when a player was last seen'
BEGIN
	IF date_start IS NULL THEN SELECT end_time FROM reset ORDER BY id DESC LIMIT 1 INTO date_start; END IF;
	IF date_start IS NULL THEN SET date_start = '1970-01-01 00:00:01'; END IF;
	IF date_end IS NULL THEN SET date_end = '2038-01-19 03:14:07'; END IF;
    
    SET @row_number := 0;
	SELECT *, (@row_number := @row_number + 1) AS Rank FROM (
	SELECT 
		squad.name AS 'Squad Name',
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
		end_time BETWEEN date_start AND date_end AND
		squad.name = name AND zone = 'EG' AND
        arena REGEXP '^[0-9]+$') summary_list;
END$$


CREATE PROCEDURE Squad_Players(
	IN name VARCHAR(24) CHARACTER SET latin1,
    date_start DATETIME,
    date_end DATETIME,
    IN max INT UNSIGNED
)  COMMENT 'Gets the lifetime stats for a player in pub arena'
BEGIN
	IF date_start IS NULL THEN SELECT end_time FROM reset ORDER BY id DESC LIMIT 1 INTO date_start; END IF;
	IF date_start IS NULL THEN SET date_start = '1970-01-01 00:00:01'; END IF;
	IF date_end IS NULL THEN SET date_end = '2038-01-19 03:14:07'; END IF;
	IF max > 100 THEN SET max = 100; END IF;
    
    SET @row_number := 0;
	SELECT *, (@row_number := @row_number + 1) AS Rank FROM (
	SELECT 
		squad.name AS 'Squad Name',
		player.name AS 'Player Name',
		MIN(flag_games.end_time) AS 'First Seen On Squad',
		MAX(flag_games.end_time) AS 'Last Seen On Squad',
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
		squad.name = name AND zone = 'EG'
			AND arena REGEXP '^[0-9]+$'
            AND squad.name != ''
			AND end_time BETWEEN date_start AND date_end
	GROUP BY player.id
	HAVING squad.name = name
	ORDER BY `points` DESC
	LIMIT max) player_list;
END$$

CREATE PROCEDURE Squad_TopPoints(
    date_start DATETIME,
    date_end DATETIME,
    IN max INT UNSIGNED
)  COMMENT 'Gets top squads by total points'
BEGIN
	IF date_start IS NULL THEN SELECT end_time FROM reset ORDER BY id DESC LIMIT 1 INTO date_start; END IF;
	IF date_start IS NULL THEN SET date_start = '1970-01-01 00:00:01'; END IF;
	IF date_end IS NULL THEN SET date_end = '2038-01-19 03:14:07'; END IF;
	IF max > 100 THEN SET max = 100; END IF;
    
    SET @row_number := 0;
	SELECT *, (@row_number := @row_number + 1) AS Rank FROM (
	SELECT 
		squad.name AS 'Squad Name',
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
            AND squad.name != ''
			AND end_time BETWEEN date_start AND date_end
	GROUP BY squad.id
    HAVING `Points` > 0
	ORDER BY `Points` DESC
	LIMIT max
    ) top_points;
END$$

DELIMITER ;
