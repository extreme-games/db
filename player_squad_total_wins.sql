SELECT pl.name, count(fs.game_id) 
FROM eg.flag_stats fs, eg.flag_games fg, eg.player pl
where fs.here = '1'
and fg.start_time > (select max(end_time) from eg.reset)
and fs.freq = fg.winning_freq
and fs.game_id = fg.id
and fs.player_id = pl.id
group by fs.player_id
order by count(fs.game_id) desc;

SELECT sq.name, count(fs.game_id) 
FROM eg.flag_stats fs, eg.flag_games fg, eg.squad sq
where fs.here = '1'
and fg.start_time > (select max(end_time) from eg.reset)
and fs.freq = fg.winning_freq
and fs.game_id = fg.id
and fs.squad_id = sq.id
and fs.squad_id != '1'
group by fs.player_id
order by count(fs.game_id) desc;