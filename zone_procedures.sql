
DROP PROCEDURE IF EXISTS TEST_Zone_SummaryHistory;

DELIMITER $$

CREATE PROCEDURE TEST_Zone_SummaryHistory(
	date_start DATETIME,
    date_end DATETIME
) RETURNS SET COMMENT 'Display zone summary statistics'
BEGIN
	IF date_start IS NULL THEN SELECT end_time FROM reset ORDER BY id DESC LIMIT 1 INTO date_start; END IF;
	IF date_start IS NULL THEN SET date_start = '1970-01-01 00:00:01'; END IF;
	IF date_end IS NULL THEN SET date_end = '2038-01-19 03:14:07'; END IF;
    
	SELECT
		SUM(warbird_time + javelin_time + spider_time + leviathan_time + terrier_time + weasal_time + lancaster_time + shark_time) / (60.0 * 60 * 24) AS `Days In Game`
		FROM flag_games INNER JOIN flag_stats ON flag_games.id = flag_stats.game_id
	WHERE zone = 'EG' AND arena REGEXP '^[0-9]+$' AND end_time BETWEEN date_start AND date_end INTO @days_in_game;

	SELECT COUNT(jackpot) AS '1 Mill JPS' FROM flag_games
	WHERE jackpot > 1000000 and zone = 'EG' AND arena REGEXP '^[0-9]+$' AND end_time BETWEEN date_start AND date_end INTO @one_mill_jackpots;
    
	SELECT SUM(jackpot) AS 'JP Points' FROM flag_games
	WHERE zone = 'EG' AND arena REGEXP '^[0-9]+$' AND end_time BETWEEN date_start AND date_end INTO @sum_jackpots;
    
	SELECT COUNT(jackpot) AS 'Total Games' FROM flag_games
	WHERE zone = 'EG' AND arena REGEXP '^[0-9]+$' AND end_time BETWEEN date_start AND date_end INTO @total_games;
	
    SELECT FORMAT(@days_in_game, 2) as 'Days In Game',
		@total_games as 'Total Games',
		@one_mill_jackpots as '1+ Mil Jackpots',
        FORMAT(@sum_jackpots,0) as 'JP Points';
END$$
