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
| ID | Action type       | Description                                       |
|----|-------------------|---------------------------------------------------|
| 0  | Pass              | Normal pass in open   play                        |
| 1  | Cross             | Cross into the box                                |
| 2  | Throw-in          | Throw-in                                          |
| 3  | Crossed free-kick | Free kick crossed   into the box                  |
| 4  | Short free-kick   | Short free-kick                                   |
| 5  | Crossed corner    | Corner crossed into   the box                     |
| 6  | Short corner      | Short corner                                      |
| 7  | Take on           | Attempt to dribble   past opponent                |
| 8  | Foul              | Foul                                              |
| 9  | Tackle            | Tackle on the ball                                |
| 10 | Interception      | Interception of the   ball                        |
| 11 | Shot              | Shot attempt not from   penalty or free-kick      |
| 12 | Penalty shot      | Penalty shot                                      |
| 13 | Free-kick shot    | Direct free-kick on   goal                        |
| 14 | Keeper save       | Keeper saves a shot   on goal                     |
| 15 | Keeper claim      | Keeper catches a   cross                          |
| 16 | Keeper punch      | Keeper punches the   ball clear                   |
| 17 | Keeper pick-up    | Keeper picks up the   ball                        |
| 18 | Clearance         | Player clearance                                  |
| 20 | Dribble           | Player dribbles at   least 3 meters with the ball |
| 21 | Goal kick         | Goal kick                                         |