WITH player_seasons AS (
   
    SELECT pr.player1_id, g.season_id, 
        pr.game_id,
        COUNT(CASE WHEN pr.event_msg_type = 'FIELD_GOAL_MADE' THEN 1 END) AS made_shots,
        COUNT(CASE WHEN pr.event_msg_type = 'FIELD_GOAL_MISSED' THEN 1 END) AS missed_shots,
    	COUNT(*) OVER (PARTITION BY pr.player1_id, g.season_id) AS games_played
    FROM play_records pr
    JOIN games g ON pr.game_id = g.id
	JOIN players p ON pr.player1_id = p.id
    WHERE g.season_type = 'Regular Season'
				AND p.first_name = {{first name}}
                AND p.last_name = {{last name}}
    GROUP BY pr.player1_id, g.season_id, pr.game_id
),
shooting_with_change AS (
  
    SELECT 
        ps.player1_id, 
        ps.season_id, 
        ps.game_id,
        CASE 
            WHEN (ps.made_shots + ps.missed_shots) = 0 THEN 0
            ELSE CAST(ps.made_shots AS FLOAT) / (ps.made_shots + ps.missed_shots)
        END AS shooting_percentage,
        LAG(
            CASE 
                WHEN (ps.made_shots + ps.missed_shots) = 0 THEN 0
                ELSE CAST(ps.made_shots AS FLOAT) / (ps.made_shots +ps.missed_shots)
            END
        ) OVER (PARTITION BY ps.player1_id, ps.season_id ORDER BY ps.game_id) AS previous_percentage
    FROM player_seasons ps
),

stability_calc AS (
    SELECT 
        player1_id, 
        season_id,
        game_id,
        ABS(shooting_percentage - COALESCE(previous_percentage, shooting_percentage)) AS change_value
    FROM shooting_with_change
)

SELECT 
    sc.season_id , 
    CAST(AVG(sc.change_value) * 100 AS DECIMAL(10,2)) AS stability

FROM stability_calc sc
JOIN player_seasons ps ON sc.player1_id = ps.player1_id AND sc.season_id = ps.season_id
WHERE ps.games_played >= 50
GROUP BY sc.season_id
ORDER BY stability ASC, season_id ASC;
