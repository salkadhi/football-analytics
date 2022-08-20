# Football Analytics

## Available Competitions From the Statsbomb Package
[Link to CSV](https://github.com/salkadhi/football-analytics/blob/main/data/competitions.csv)

## Match Events Dictionary From Official Documentaion
[Link to pdf](https://github.com/salkadhi/football-analytics/blob/main/specs/Open%20Data%20Events%20v4.0.0.pdf)

## Player Valuations in A Competitions From Transfermarket
[Link to CSV](https://github.com/salkadhi/football-analytics/blob/main/data/tm_player_valuations_all_1617-2122_latest.csv)

## Converted Action Events Using SPADL Format
| team_id      | a unique identifier of the team who performed the action                         |
|--------------|----------------------------------------------------------------------------------|
| player_id    | a unique identifier of the player who performed the action                       |
| period       | 1 for the first half and 2 for the second half                                   |
| seconds      | the time elapsed in seconds since the start of the half                          |
| type_id      | the identifier for the type of action                                            |
| type_name    | the name for the type of action                                                  |
| body_part_id | 0 for foot, 1 for head, 2 for other body part                                    |
| result       | the result of the action: 0 for failure, 1 for success                           |
| start_x      | the x coordinate for the location where the action started, ranges from 0 to 105 |
| start_y      | the y coordinate for the location where the action started, ranges from 0 to 68  |
| end_x        | the x coordinate for the location where the action ended, ranges from 0 to 105   |
| end_y        | the y coordinate for the location where the action ended, ranges from 0 to 68    |
