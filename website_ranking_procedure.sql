TRUNCATE TABLE  egstats.player_kpm;

INSERT INTO egstats.player_kpm (player_name, match_date, kpm, game_id, modified_on) 
SELECT pl.name, date_format(fg.end_time,'%Y-%m-%d') as match_date, fs.wins/((fs.warbird_time + fs.javelin_time + fs.spider_time + fs.leviathan_time + fs.terrier_time + fs.weasal_time + fs.lancaster_time + fs.shark_time)/60) as KPM, fs.game_id, now()
FROM eg.flag_stats fs, eg.flag_games fg, eg.player pl, eg.pub_stats ps
where fg.start_time > (select max(end_time) from eg.reset)
and fs.game_id = fg.id
and fs.player_id = pl.id
and ps.player_id = pl.id
and ((fs.warbird_time + fs.javelin_time + fs.spider_time + fs.leviathan_time + fs.terrier_time + fs.weasal_time + fs.lancaster_time + fs.shark_time)/60) > 10
and ps.losses > '50'
order by fs.wins/((fs.warbird_time + fs.javelin_time + fs.spider_time + fs.leviathan_time + fs.terrier_time + fs.weasal_time + fs.lancaster_time + fs.shark_time)/60) desc;

TRUNCATE TABLE egstats.player_kpm_agg;

INSERT INTO egstats.player_kpm_agg (player_name, kpm_avg, modified_on)
SELECT player_name, avg(kpm) as kpm_avg, now() FROM egstats.player_kpm
group by player_name;

SELECT 
    @wins_median:=MAX(wins) / 2 AS Win_Median
FROM
    eg.pub_stats;

SELECT 
    @loss_median:=MAX(losses) / 2 AS Loss_Median
FROM
    eg.pub_stats;

SELECT 
    @kd_median:=((wins) / (losses)) / 2 AS KD_Median
FROM
    eg.pub_stats
    where losses > '50'
ORDER BY ((wins) / (losses)) / 2 DESC
LIMIT 1;

SELECT 
    @points_median:=(flag_points + kill_points) / 2 AS Points_Median
FROM
    eg.pub_stats
WHERE losses > '50'
ORDER BY (flag_points + kill_points) / 2 DESC
LIMIT 1;

SELECT 
    @kpm_median:=max(kpm_avg) /2 from egstats.player_kpm_agg;

TRUNCATE TABLE  egstats.zone_medians;

Insert into egstats.zone_medians (wins_median, losses_median, kdratio_median, kpm_median, points_median, modified_on)
values (@wins_median,@loss_median,@kd_median,@kpm_median,@points_median, NOW());

Drop table player_rank;

SELECT 
    @kpm_value:=kpm_median
FROM
    egstats.zone_medians;

CREATE TABLE player_rank SELECT pl.name AS player_name,
    sq.name AS squad,
    ROUND(((ps.flag_points + ps.kill_points) / (zm.points_median) * 100),
            2) AS points_rank,
    ROUND((((ps.wins) / (ps.losses)) / (zm.kdratio_median) * 100),
            2) AS kd_rank,
    ROUND(((pk.kpm_avg / (@kpm_value)) * 100), 2) kpm_rank,
    ROUND(((((pk.kpm_avg / (@kpm_value)) * 100) + (((ps.wins) / (ps.losses)) / (zm.kdratio_median) * 100) + ((ps.flag_points + ps.kill_points) / (zm.points_median) * 100)) / 3),
            2) AS pub_rank,
    NOW() AS modified_on FROM
    eg.pub_stats ps,
    eg.player pl,
    eg.squad sq,
    egstats.zone_medians zm,
    eg.flag_games fg,
    egstats.player_kpm_agg pk
WHERE
    ps.player_id = pl.id
        AND zm.modified_on = (SELECT 
            MAX(zm.modified_on)
        FROM
            egstats.zone_medians)
        AND fg.start_time > (SELECT 
            MAX(end_time)
        FROM
            eg.reset)
        AND ps.losses > '50'
        AND sq.id = ps.squad_id
        AND pl.name = pk.player_name
GROUP BY pl.name , sq.name
ORDER BY pub_rank DESC;