
DROP PROCEDURE IF EXISTS Player_PubStats;
DROP PROCEDURE IF EXISTS Player_LastSeen;
DROP PROCEDURE IF EXISTS Player_Timezone;
DROP PROCEDURE IF EXISTS Player_SquadHistory;

DELIMITER $$

CREATE PROCEDURE Player_PubStats(
	IN name VARCHAR(24) CHARACTER SET latin1,
    date_start DATETIME,
    date_end DATETIME
)  COMMENT 'Gets the lifetime stats for a player in pub arena'
BEGIN
	IF date_start IS NULL THEN SELECT end_time FROM reset ORDER BY id DESC LIMIT 1 INTO date_start; END IF;
	IF date_start IS NULL THEN SET date_start = '1970-01-01 00:00:01'; END IF;
	IF date_end IS NULL THEN SET date_end = '2038-01-19 03:14:07'; END IF;
    
	SELECT
		SUM(spectator_time) / (60.0 * 60 * 24) as 'Days in Spec',
		SUM(warbird_time + javelin_time + spider_time + leviathan_time + terrier_time + weasal_time + lancaster_time + shark_time) / (60.0 * 60 * 24) as 'Days In Game',
        SUM(flag_points + kill_points + total_kothpoints + IF(winning_freq = freq && here != 0, jackpot, 0)) as 'Points',
        SUM(wins) as 'Kills',
        SUM(losses) as 'Deaths',
        SUM(teamkills) as 'Teamkills',
        SUM(flags_dropped) as 'Flags Dropped',
        SUM(attaches) as 'Other Players Attached',
		SUM(attached_to) as 'Attached To',
		SUM(total_greens) as 'Total Greens',
        SUM(goals) as 'Goals Scored',
        MAX(IF (winning_freq  = freq, jackpot, 0)) as 'Largest Jackpot Won',
        MAX(IF (winning_freq != freq, jackpot, 0)) as 'Largest Jackpot Lost'
		FROM flag_stats INNER JOIN player ON player.id = flag_stats.player_id
		INNER JOIN flag_games ON
		flag_games.id = flag_stats.game_id
WHERE player.name = name AND zone = 'EG' AND arena REGEXP '^[0-9]+$' AND end_time BETWEEN date_start AND date_end;
END$$

CREATE PROCEDURE Player_LastSeen(
	IN name VARCHAR(24) CHARACTER SET latin1
)  COMMENT 'Gets the date a player was last seen in EG'
BEGIN
	SELECT date FROM info WHERE info.name = name ORDER BY date DESC LIMIT 1;
END$$

CREATE PROCEDURE Player_Timezone(
	IN name VARCHAR(24) CHARACTER SET latin1
)  COMMENT 'Gets the players timezone'
BEGIN
	SELECT -FLOOR(tz / 60) as Timezone FROM info WHERE info.name = name ORDER BY date DESC LIMIT 1;
END$$

CREATE PROCEDURE Player_SquadHistory(
	IN name VARCHAR(24) CHARACTER SET latin1,
    IN min_days FLOAT
)  COMMENT 'Gets the lifetime stats for a player in pub arena'
BEGIN
	SELECT
		squad.name AS 'Squad Name',
        MIN(flag_games.end_time) AS 'First On',
        MAX(flag_games.end_time) AS 'Last On',
		SUM(warbird_time + javelin_time + spider_time + leviathan_time + terrier_time + weasal_time + lancaster_time + shark_time) / (60.0 * 60 * 24) as `Days In Game`,
		SUM(spectator_time) / (60.0 * 60 * 24) as 'Days in Spec',
        SUM(flag_points + kill_points + total_kothpoints + IF(winning_freq = freq && here != 0, jackpot, 0)) as 'Points',
        SUM(wins) as 'Kills',
        SUM(losses) as 'Deaths',
        SUM(teamkills) as 'Teamkills',
        SUM(flags_dropped) as 'Flags Dropped',
        SUM(attaches) as 'Other Players Attached',
		SUM(attached_to) as 'Attached To',
		SUM(total_greens) as 'Total Greens',
        SUM(goals) as 'Goals Scored',
        MAX(IF (winning_freq  = freq, jackpot, 0)) as 'Largest Jackpot Won',
        MAX(IF (winning_freq != freq, jackpot, 0)) as 'Largest Jackpot Lost'
		FROM flag_stats INNER JOIN player ON player.id = flag_stats.player_id
		INNER JOIN flag_games ON flag_games.id = flag_stats.game_id
        INNER JOIN squad ON squad.id = flag_stats.squad_id
		WHERE player.name = name AND zone = 'EG' AND arena REGEXP '^[0-9]+$'
        GROUP BY squad.id
        HAVING `Days In Game` >= min_days
        ORDER BY `Last On` DESC;
END$$

DELIMITER ;
