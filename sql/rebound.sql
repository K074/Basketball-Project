WITH window_e AS(
SELECT 
	players.id as player_id,
	players.first_name as player_name,
	players.last_name as player_last, 
	pr.period as per,
	pr.pctimestring as period_time, 
	pr.event_number as evenum, 
	event_msg_type as eve,
	LEAD (pr.event_msg_type) OVER (
								PARTITION BY pr.game_id 	
								ORDER BY event_number) as nexte

FROM play_records pr

LEFT JOIN players ON pr.player1_id = players.id

WHERE   game_id =  22000529
)

SELECT  w1.player_id,
			w1.player_name,w2.player_name,
				w1.player_last,
				
					w2.per,
						
						w2.period_time
 FROM window_e w1
 JOIN window_e w2 ON w1.player_id = w2.player_id
 				AND  w1.evenum + 1 = w2.evenum
WHERE       
			w1.eve = 'REBOUND'
       and w2.eve = 'FIELD_GOAL_MADE'

ORDER BY w1.per, w1.period_time DESC, w1.player_id