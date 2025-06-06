WITH team_games AS (
    SELECT 
        g.id AS game_id, 
        g.home_team_id, 
        g.away_team_id, 
        th.team_id, 
        th.city || ' ' || th.nickname AS team_name,
        th.year_founded,
        COALESCE(th.year_active_till, 2019) AS active_till,
        CASE 
            WHEN COALESCE(th.year_active_till, 2019) = 2019 THEN NULL
            ELSE MAKE_DATE(th.year_active_till, 6, 30) 
        END AS end_date,
        MAKE_DATE(th.year_founded, 7, 1) AS start_date,
        g.game_date
    FROM games g
    JOIN team_history th ON th.team_id IN (g.home_team_id, g.away_team_id)
),

filtered_games AS (
    SELECT 
        tg.team_id,
        tg.team_name,
        COUNT(CASE WHEN tg.team_id = tg.home_team_id THEN 1 END) AS home_games,
        COUNT(CASE WHEN tg.team_id = tg.away_team_id THEN 1 END) AS away_games
    FROM team_games tg
    WHERE tg.game_date BETWEEN tg.start_date AND COALESCE(tg.end_date, '3000-01-01')
    GROUP BY tg.team_id, tg.team_name
)
SELECT 
    fg.team_id AS "team id",
    fg.team_name AS "team name",
    fg.away_games AS "number away matches",
    ROUND(100.0 * fg.away_games / NULLIF(fg.away_games + fg.home_games, 0), 2) AS "percentage away matches",
    fg.home_games AS "number home matches",
    ROUND(100.0 * fg.home_games / NULLIF(fg.away_games + fg.home_games, 0), 2) AS "percentage home matches",
    (fg.away_games + fg.home_games) AS "total games"
FROM filtered_games fg
ORDER BY fg.team_id ASC, fg.team_name ASC;
