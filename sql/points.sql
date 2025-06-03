WITH shot_stats AS (
    SELECT 
        pr.player1_id AS player_id,
        p.first_name,
        p.last_name,
        g.id AS game_id,
        SUM(CASE 
            WHEN pr.event_msg_type = 'FIELD_GOAL_MADE' AND pr.event_msg_action_type > 3   THEN 2
            WHEN pr.event_msg_type = 'FIELD_GOAL_MADE' AND pr.event_msg_action_type < 3   THEN 3
            WHEN pr.event_msg_type = 'FREE_THROW' AND pr.score_margin IS NOT NULL THEN 1
            ELSE 0 
        END) AS points,
        COUNT(CASE WHEN pr.event_msg_type = 'FIELD_GOAL_MADE' AND pr.event_msg_action_type > 3
																THEN 1 ELSE NULL END) AS "2PM",
        COUNT(CASE WHEN pr.event_msg_type = 'FIELD_GOAL_MADE' AND pr.event_msg_action_type < 3
															     THEN 1 ELSE NULL END) AS "3PM",
        COUNT(CASE WHEN pr.event_msg_type = 'FIELD_GOAL_MISSED' THEN 1 ELSE NULL END) AS missed_shots,
        COUNT(CASE WHEN pr.event_msg_type = 'FREE_THROW' AND pr.score_margin IS NOT NULL THEN 1 ELSE NULL END) AS FTM,
        COUNT(CASE WHEN pr.event_msg_type = 'FREE_THROW' AND pr.score_margin IS NULL THEN 1 ELSE NULL END) AS missed_free_throws
    FROM play_records pr
    JOIN games g ON pr.game_id = g.id
    JOIN players p ON pr.player1_id = p.id
    WHERE g.id = '21701185'
    GROUP BY pr.player1_id, p.first_name, p.last_name, g.id
)
SELECT 
    player_id,
    first_name,
    last_name,
    points,
    "2PM",
    "3PM",
    missed_shots,
    COALESCE(ROUND((("2PM" + "3PM")::DECIMAL / NULLIF("2PM" + "3PM" + missed_shots, 0)) * 100, 2) , 0.00 ) AS shooting_percentage,
    FTM,
    missed_free_throws,
    COALESCE(ROUND((FTM::DECIMAL / NULLIF(FTM + missed_free_throws, 0)) * 100, 2 ) , 0.00)  AS FT_percentage 
FROM shot_stats
ORDER BY 
    points DESC,
    shooting_percentage DESC,
    FT_percentage DESC,
    player_id ASC;
