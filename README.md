# Football Analytics

## Introduction

Football analytics is a growing industry within the sport that every top team can’t neglect to utilize. While football has be slow to catch up with American sports in harnessing data as a valuable resource, the analytics industry now spans academia, data providers, gambling companies, and more. Part of the reason football has lagged behind baseball and basketball in this field was due to its low-scoring nature, and long stretches of un-interrupted play. In addition, because goal-scoring is the only determining factor for winning matches, the earliest statistical metrics were biased and could not fairly assess every player in the team. 

Recently, machine learning algorithms have been published to help quantify the average positive (or negative) impact all actions taken by team members in a game. For my project, I will use the newly developed tool VAEP (Valuing Actions by Estimating probabilities) to compute every player impact in the recent Euro 2020 tournament. In addition, I will also the fairly recent xT (expected threat), and the older xG (expected goals) frameworks. In my analysis, I provide correlations between these statistics and the player’s market value on the popular transfermarkt website. I conclude with using these results to find undervalued players with high performance in this competition. 

## HTML Jupyter Notebook
[Link](https://salkadhi.github.io/football-analytics/)

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

## SPADL Action Type Definitions
|    Action type    |                   Description                   |        Success?        |   Special result   |
|:-----------------:|:-----------------------------------------------:|:----------------------:|:------------------:|
| Pass              | Normal pass in open play                        | Reaches teammate       | Offside            |
| Cross             | Cross into the box                              | Reaches teammate       | Offside            |
| Throw-in          | Throw-in                                        | Reaches teammate       | /                  |
| Crossed free-kick | Free kick crossed into the box                  | Reaches teammate       | Offside            |
| Short free-kick   | Short free-kick                                 | Reaches team mate      | Offside            |
| Crossed corner    | Corner crossed into the box                     | Reaches teammate       | /                  |
| Short corner      | Short corner                                    | Reaches teammate       | /                  |
| Take on           | Attempt to dribble past opponent                | Keeps possession       | /                  |
| Foul              | Foul                                            | Always fail            | Red or yellow card |
| Tackle            | Tackle on the ball                              | Regains possession     | /                  |
| Interception      | Interception of the ball                        | Regains possession     | /                  |
| Shot              | Shot attempt not from penalty or free-kick      | Goal                   | Own goal           |
| Penalty shot      | Penalty shot                                    | Goal                   | /                  |
| Free-kick shot    | Direct free-kick on goal                        | Goal                   | /                  |
| Keeper save       | Keeper saves a shot on goal                     | Always success         | /                  |
| Keeper claim      | Keeper catches a cross                          | Does not drop the ball | /                  |
| Keeper punch      | Keeper punches the ball clear                   | Always success         | /                  |
| Keeper pick-up    | Keeper picks up the ball                        | Always success         | /                  |
| Clearance         | Player clearance                                | Always success         | /                  |
| Bad touch         | Player makes a bad touch and loses the ball     | Always fail            | /                  |
| Dribble           | Player dribbles at least 3 meters with the ball | Always success         | /                  |
| Goal kick         | Goal kick                                       | Always success         | /                  |


## Feature Dictionary of the Game State
|   Transformer   |         Feature        |                                                     Description                                                    |
|:---------------:|:----------------------:|:------------------------------------------------------------------------------------------------------------------:|
| actiontype()    | actiontype(_onehot)_ai | The (one-hot encoding) of the action’s type.                                                                       |
| result()        | result(_onehot)_ai     | The (one-hot encoding) of the action’s result.                                                                     |
| bodypart()      | actiontype(_onehot)_ai | The (one-hot encoding) of the bodypart used to perform the action.                                                 |
| time()          | time_ai                | Time in the match the action takes place, recorded to the second.                                                  |
| startlocation() | start_x_ai             | The x pitch coordinate of the action’s start location.                                                             |
|                 | start_y_ai             | The y pitch coordinate of the action’s start location.                                                             |
| endlocation()   | end_x_ai               | The x pitch coordinate of the action’s end location.                                                               |
|                 | end_y_ai               | The y pitch coordinate of the action’s end location.                                                               |
| startpolar()    | start_dist_to_goal_ai  | The distance to the center of the goal from the action’s start location.                                           |
|                 | start_angle_to_goal_ai | The angle between the action’s start location and center of the goal.                                              |
| endpolar()      | end_dist_to_goal_ai    | The distance to the center of the goal from the action’s end location.                                             |
|                 | end_angle_to_goal_ai   | The angle between the action’s end location and center of the goal.                                                |
| movement()      | dx_ai                  | The distance covered by the action along the x-axis.                                                               |
|                 | dy_ai                  | The distance covered by the action along the y-axis.                                                               |
|                 | movement_ai            | The total distance covered by the action.                                                                          |
| team()          | team_ai                | Boolean indicating whether the team that had possesion in action  ai−2 still has possession in the current action. |
| time_delta()    | time_delta_i           | Seconds elapsed between  ai−2 and the current action.                                                              |
| space_delta()   | dx_a0i                 | The distance covered by action  ai−2 to  ai along the x-axis.                                                      |
|                 | dy_a0i                 | The distance covered by action  ai−2 to  ai along the y-axis.                                                      |
|                 | mov_a0i                | The total distance covered by action  ai−2 to  ai.                                                                 |
| goalscore()     | goalscore_team         | The number of goals scored by the team executing the action.                                                       |
|                 | goalscore_opponent     | The number of goals scored by the other team.                                                                      |
|                 | goalscore_diff         | The goal difference between both teams.                                                                            |
## References
https://github.com/ML-KULeuven/socceraction

Actions speak louder than goals: Valuing player actions in soccer. T Decroos, L Bransen, J Van Haaren. - Proceedings of the 25th ACM SIGKDD International Conference on Knowledge Discovery & Data Mining. 2019 

Valuing on-the-ball actions in soccer: a critical comparison of XT and VAEP. Maaike Van Roy, Pieter Robberechts, Tom Decroos, Jesse Davis. In Proceedings of the AAAI-20 Workshop on Artifical Intelligence in Team Sports. AI in Team Sports Organising Committee. 2020.

