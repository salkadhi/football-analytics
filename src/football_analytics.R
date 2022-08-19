library(pacman)
p_load(tidyverse, StatsBombR, worldfootballR, SBpitch, grid)

# Set Comp to LaLiga 2020/2021 ----
Comp <- FreeCompetitions() %>%
  filter(competition_id==11 & season_name=="2020/2021") 

# Pull in Matches ----
Matches <- FreeMatches(Comp)

# Create laliga20 DF of All Events for the Seaons ----
laliga20 <- free_allevents(MatchesDF = Matches, Parallel = T)

# Clean DF with SB allclean() Method ----
#adds 37 columns
la_liga20 = allclean(laliga20)
rm(laliga20)

#Data Specs ----
#https://github.com/statsbomb/open-data/blob/master/doc/Open%20Data%20Events%20v4.0.0.pdf
#https://github.com/statsbomb/open-data/blob/master/doc/StatsBomb%20Open%20Data%20Specification%20v1.1.pdf

#Group by Team and Create a New DF. 'shots' Column Sums Up All Rows Containing 'Shot' Ignoring NAs. 'goals' Does the Same for Goals ----
shots_goals = la_liga20 %>%
  group_by(team.name) %>% 
  summarise(shots = sum(type.name=="Shot", na.rm = TRUE),
            goals = sum(shot.outcome.name=="Goal", na.rm = TRUE)) 

#Divide Number of Shots or Goals by Each Unique Instance of a Match ID for Every Team.----
shots_goals_per_game = la_liga20 %>%
  group_by(team.name) %>%
  summarise(shots = sum(type.name=="Shot", na.rm = TRUE)/n_distinct(match_id),
            goals = sum(shot.outcome.name=="Goal", na.rm = TRUE)/n_distinct(match_id))

# Plot Shots Per Game in Descending Order, Geom Bar, Rename Y Label, Move Bars Closer to Edge, Flip Plot.----
ggplot(data = shots_goals_per_game,
       aes(x = reorder(team.name, shots), y = shots)) + 
  geom_bar(stat = "identity", width = 0.5) + 
  labs(y="Shots") + 
  theme(axis.title.y = element_blank()) + 
  scale_y_continuous( expand = c(0,0)) +
  coord_flip() 
  # theme_SB() 

# Create a Player Shots DF ----
player_shots = la_liga20 %>%
  group_by(player.name, player.id) %>%
  summarise(shots = sum(type.name=="Shot", na.rm = TRUE)) 

# Function to Return Minutes Played in Each Match ----
player_minutes_match = get.minutesplayed(la_liga20) 

#Sum Total League Minutes Played ----
player_minutes_total = player_minutes_match %>%
  group_by(player.id) %>%
  summarise(minutes = sum(MinutesPlayed))

#Combine player_shots w player_minutes_total ----
player_shots = left_join(player_shots, player_minutes_total)

# Add a 'ninties' Column ----
player_shots = player_shots %>% mutate(nineties = minutes/90) 

# Divide Shots by Ninties ----
player_shots = player_shots %>% mutate(shots_per90 = shots/nineties) 
# clean this w 'filter' to remove players with few minutes played.

# Frenkie de Jong's Passes. Filter for Completed and Inside the Box. Coordinates Available in Specs ----
fdj_passes = la_liga20 %>%
  filter(type.name=="Pass" & is.na(pass.outcome.name) &
           player.id==8118) %>%
  filter(pass.end_location.x>=102 & pass.end_location.y<=62 &
           pass.end_location.y>=18) 

# Create a Pitch w Pass Arrows From X/Y to Xend/Yend. Customize w Lineend, Size, Length. Scale_Y_Reverse Fixed the Angles. Fix Aspect Ratio to Prevent Stretching.----
create_Pitch() +
  geom_segment(data = fdj_passes, aes(x = location.x, y = location.y,
                                  xend = pass.end_location.x, yend = pass.end_location.y),
               lineend = "round", size = 0.5, colour = "#000000", arrow =
                 arrow(length = unit(0.07, "inches"), ends = "last", type = "open")) + 
  labs(title = "Frenkie de Jong, Completed Box Passes", subtitle = "La Liga,
2020-21") +
  scale_y_reverse() +
  coord_fixed(ratio = 105/100) 
  # annotate_pitchSB()
#use color in geom_segment to color the passes according to what you choose

# Create a XGA DF W Pass IDs Preceding Shots & Shot XG (Renamed to XGA) ----
xGA = la_liga20 %>%
  filter(type.name=="Shot") %>% 
  select(shot.key_pass_id, xGA = shot.statsbomb_xg) 

#Join la_liga20 W XGA via shot.key_pass_id & Filter for Relevant Columns ----
shot_assists = left_join(la_liga20, xGA, by = c("id" = "shot.key_pass_id"))%>% 
  select(team.name, player.name, player.id, type.name, pass.shot_assist,
         pass.goal_assist, xGA ) %>% 
  filter(pass.shot_assist==TRUE | pass.goal_assist==TRUE) 

# Group by Player & Computing Total xGA for the Season ----
player_xGA = shot_assists %>%
  group_by(player.name, player.id, team.name) %>%
  summarise(xGA = sum(xGA, na.rm = TRUE))

# Filter out Penalties From la_liga20. Summing Each Player xG. Joing W player_xGA. Create a Column of xG + xGA (Note When One of Them is Null)----
player_xG = la_liga20 %>%
  filter(type.name=="Shot") %>%
  filter(shot.type.name!="Penalty" | is.na(shot.type.name)) %>%
  group_by(player.name, player.id, team.name) %>%
  summarise(xG = sum(shot.statsbomb_xg, na.rm = TRUE)) %>%
  left_join(player_xGA) %>%
  mutate(xG_xGA = sum(xG+xGA, na.rm =TRUE) ) 

# Join to player_minutes_total. Add ninties. Divide Stats by it.---
player_xG_xGA = left_join(player_xG, player_minutes_total) %>%
  mutate(nineties = minutes/90,
         xG_90 = round(xG/nineties, 2),
         xGA_90 = round(xGA/nineties,2),
         xG_xGA90 = round(xG_xGA/nineties,2) )

# Filter to Min 600 Mins. top_n to Filter Based on Certain Column Criteria.----
chart = player_xG_xGA %>%
  ungroup() %>%
  filter(minutes>=600) %>%
  top_n(n = 15, w = xG_xGA90) 

#Flatten the Data (xG_90, xGA_90 in Separate Rows). Filter.----
chart<-chart %>%
  select(1, 9:10)%>%
  pivot_longer(-player.name, names_to = "variable", values_to = "value") %>%
  filter(variable=="xG_90" | variable=="xGA_90") 
chart

# Plot xG_90, xGA_90 Chart in Descending Order. Use Variable in Fill to Stack.----
ggplot(chart, aes(x =reorder(player.name, value), y = value, fill=fct_rev(variable))) + 
  geom_bar(stat="identity", colour="white")+
  labs(title = "Expected Goal Contribution", subtitle = "La Liga, 2020-21",
       x="", y="Per 90", caption ="Minimum 600 minutes\nNPxG = Value of shots taken (no penalties)\nxG assisted = Value of shots assisted")+
  theme(axis.text.y = element_text(size=14, color="#333333", family="Source Sans Pro"),
        axis.title = element_text(size=14, color="#333333", family="Source Sans Pro"),
        axis.text.x = element_text(size=14, color="#333333", family="Source Sans Pro"),
        axis.ticks = element_blank(),
        panel.background = element_rect(fill = "white", colour = "white"),
        plot.background = element_rect(fill = "white", colour ="white"),
        panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        plot.title=element_text(size=24, color="#333333", family="Source Sans Pro" , face="bold"),
        plot.subtitle=element_text(size=18, color="#333333", family="Source Sans Pro", face="bold"),
        plot.caption=element_text(color="#333333", family="Source Sans Pro", size =10),
        text=element_text(family="Source Sans Pro"),
        legend.title=element_blank(),
        legend.text = element_text(size=14, color="#333333", family="Source Sans Pro"),
        legend.position = "bottom") + 
  scale_fill_manual(values=c("#3371AC", "#DC2228"), labels = c( "xG Assisted","NPxG")) + 
  scale_y_continuous(expand = c(0, 0), limits= c(0,max(chart$value) + 0.3)) + 
  coord_flip()+ 
  guides(fill = guide_legend(reverse = TRUE)) 


# If the Coordinates are Outside Bounds Replace W Max ----
heatmap = la_liga20 %>%mutate(location.x = ifelse(location.x>120, 120, location.x),
                           location.y = ifelse(location.y>80, 80, location.y),
                           location.x = ifelse(location.x<0, 0, location.x),
                           location.y = ifelse(location.y<0, 0, location.y)) 
# Split the Axes into Size 20 Bins
heatmap$xbin <- cut(heatmap$location.x, breaks = seq(from=0, to=120, by = 20),include.lowest=TRUE )
heatmap$ybin <- cut(heatmap$location.y, breaks = seq(from=0, to=80, by = 20),include.lowest=TRUE) #2

# Filter to Defensive Events. Group & Total by Team. Group Again & Count Them in the Bins. Get Percentages. Ungroup & Mutate for League Average. Then Group Again & Subtract League Avg.  ---- 
heatmap = heatmap%>%
  filter(type.name=="Pressure" | duel.type.name=="Tackle" |
           type.name=="Foul Committed" | type.name=="Interception" |
           type.name=="Block" ) %>%
  group_by(team.name) %>%
  mutate(total_DA = n()) %>%
  group_by(team.name, xbin, ybin) %>%
  summarise(total_DA = max(total_DA),
            bin_DA = n(),
            bin_pct = bin_DA/total_DA,
            location.x = median(location.x),
            location.y = median(location.y)) %>%
  group_by(xbin, ybin) %>%
  mutate(league_ave = mean(bin_pct)) %>%
  group_by(team.name, xbin, ybin) %>%
  mutate(diff_vs_ave = bin_pct - league_ave) 

defensiveactivitycolors <- c("#dc2429", "#dc2329", "#df272d", "#df3238", "#e14348", "#e44d51",
                             "#e35256", "#e76266", "#e9777b", "#ec8589", "#ec898d", "#ef9195",
                             "#ef9ea1", "#f0a6a9", "#f2abae", "#f4b9bc", "#f8d1d2", "#f9e0e2",
                             "#f7e1e3", "#f5e2e4", "#d4d5d8", "#d1d3d8", "#cdd2d6", "#c8cdd3", "#c0c7cd",
                             "#b9c0c8", "#b5bcc3", "#909ba5", "#8f9aa5", "#818c98", "#798590",
                             "#697785", "#526173", "#435367", "#3a4b60", "#2e4257", "#1d3048",
                             "#11263e", "#11273e", "#0d233a", "#020c16")


#geom_bin2d Creates the Heatmap. Setting Color by diff_vs_ave in Fill & Group. Lines Draw the Pitch. Reverse Axis Because 0 is Left in SB Coordinates. scale_fill_gradientn to defensiveactivitycolors we set earlier. Reverse Output so Red is High. Format the Text a Percentages. Set Limits of Chart. Reverse Because of Previous Reverse. Use Grid Package to Indicate Direction of Play. Facet Wrap for Each Team. Get Back the Legend from Previous Reverse. ---- 
ggplot(data= heatmap, aes(x = location.x, y = location.y, fill = diff_vs_ave, group =diff_vs_ave)) +
  geom_bin2d(binwidth = c(20, 20), position = "identity", alpha = 0.9) +
  annotate("rect",xmin = 0, xmax = 120, ymin = 0, ymax = 80, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 0, xmax = 60, ymin = 0, ymax = 80, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 18, xmax = 0, ymin = 18, ymax = 62, fill = NA, colour = "white", size = 0.6) +
  annotate("rect",xmin = 102, xmax = 120, ymin = 18, ymax = 62, fill = NA, colour = "white", size = 0.6) +
  annotate("rect",xmin = 0, xmax = 6, ymin = 30, ymax = 50, fill = NA, colour = "white", size = 0.6) +
  annotate("rect",xmin = 120, xmax = 114, ymin = 30, ymax = 50, fill = NA, colour = "white", size = 0.6) +
  annotate("rect",xmin = 120, xmax = 120.5, ymin =36, ymax = 44, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 0, xmax = -0.5, ymin =36, ymax = 44, fill = NA, colour = "black", size = 0.6) +
  annotate("segment", x = 60, xend = 60, y = -0.5, yend = 80.5, colour = "white", size = 0.6)+
  annotate("segment", x = 0, xend = 0, y = 0, yend = 80, colour = "black", size = 0.6)+
  annotate("segment", x = 120, xend = 120, y = 0, yend = 80, colour = "black", size = 0.6)+
  theme(rect = element_blank(),
        line = element_blank()) +
  annotate("point", x = 12 , y = 40, colour = "white", size = 1.05) +
  annotate("point", x = 108 , y = 40, colour = "white", size = 1.05) +
  annotate("path", colour = "white", size = 0.6,
           x=60+10*cos(seq(0,2*pi,length.out=2000)),
           y=40+10*sin(seq(0,2*pi,length.out=2000)))+
  annotate("point", x = 60 , y = 40, colour = "white", size = 1.05) +
  annotate("path", x=12+10*cos(seq(-0.3*pi,0.3*pi,length.out=30)), size = 0.6,
           y=40+10*sin(seq(-0.3*pi,0.3*pi,length.out=30)), col="white") +
  annotate("path", x=108-10*cos(seq(-0.3*pi,0.3*pi,length.out=30)), size = 0.6,
           y=40-10*sin(seq(-0.3*pi,0.3*pi,length.out=30)), col="white") +
  theme(axis.text.x=element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        plot.caption=element_text(size=13,family="Source Sans Pro", hjust=0.5, vjust=0.5),
        plot.subtitle = element_text(size = 18, family="Source Sans Pro", hjust = 0.5),
        axis.text.y=element_blank(),
        legend.title = element_blank(),
        legend.text=element_text(size=22,family="Source Sans Pro"),
        legend.key.size = unit(1.5, "cm"),
        plot.title = element_text(margin = margin(r = 10, b = 10), face="bold",size = 32.5,
                                  family="Source Sans Pro", colour = "black", hjust = 0.5),
        legend.direction = "vertical",
        axis.ticks=element_blank(),
        plot.background = element_rect(fill = "white"),
        strip.text.x = element_text(size=13,family="Source Sans Pro")) + 
  scale_y_reverse() + 
  scale_fill_gradientn(colours = defensiveactivitycolors, trans = "reverse", labels =
                         scales::percent_format(accuracy = 1), limits = c(0.03, -0.03)) + 
  labs(title = "Where Do Teams Defend vs League Average?", subtitle = "La Liga, 2020/21") + 
  coord_fixed(ratio = 95/100) + 
  annotation_custom(grob = linesGrob(arrow=arrow(type="open", ends="last",
                                                 length=unit(2.55,"mm")), gp=gpar(col="black", fill=NA, lwd=2.2)),
                    xmin=25, xmax = 95, ymin = -83, ymax = -83) +
  facet_wrap(~team.name)+ 
  guides(fill = guide_legend(reverse = TRUE)) 

# Create Shot DF for FDJ. ----
fdj_shots = la_liga20 %>%
  filter(type.name=="Shot" & (shot.type.name!="Penalty" | is.na(shot.type.name)) & player.name=="Frenkie de Jong") 

shotmapxgcolors <- c("#192780", "#2a5d9f", "#40a7d0", "#87cdcf", "#e7f8e6", "#f4ef95", "#FDE960", "#FCDC5F",
                     "#F5B94D", "#F0983E", "#ED8A37", "#E66424", "#D54F1B", "#DC2608", "#BF0000", "#7F0000", "#5F0000") #2

# Shapes Numbered 21 and up Have Inner Coloring (Controlled by Fill) & Outline Coloring (Coontrolled by Colour). oob=scales::squish Squished the Outside Bounds Values. guides() Alters the Legend for Shape/Fill/etc. ----
ggplot() +
  annotate("rect",xmin = 0, xmax = 120, ymin = 0, ymax = 80, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 0, xmax = 60, ymin = 0, ymax = 80, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 18, xmax = 0, ymin = 18, ymax = 62, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 102, xmax = 120, ymin = 18, ymax = 62, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 0, xmax = 6, ymin = 30, ymax = 50, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 120, xmax = 114, ymin = 30, ymax = 50, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 120, xmax = 120.5, ymin =36, ymax = 44, fill = NA, colour = "black", size = 0.6) +
  annotate("rect",xmin = 0, xmax = -0.5, ymin =36, ymax = 44, fill = NA, colour = "black", size = 0.6) +
  annotate("segment", x = 60, xend = 60, y = -0.5, yend = 80.5, colour = "black", size = 0.6)+
  annotate("segment", x = 0, xend = 0, y = 0, yend = 80, colour = "black", size = 0.6)+
  annotate("segment", x = 120, xend = 120, y = 0, yend = 80, colour = "black", size = 0.6)+
  theme(rect = element_blank(),
        line = element_blank()) +
  # add penalty spot right
  annotate("point", x = 108 , y = 40, colour = "black", size = 1.05) +
  annotate("path", colour = "black", size = 0.6,
           x=60+10*cos(seq(0,2*pi,length.out=2000)),
           y=40+10*sin(seq(0,2*pi,length.out=2000)))+
  # add centre spot
  annotate("point", x = 60 , y = 40, colour = "black", size = 1.05) +
  annotate("path", x=12+10*cos(seq(-0.3*pi,0.3*pi,length.out=30)), size = 0.6,
           y=40+10*sin(seq(-0.3*pi,0.3*pi,length.out=30)), col="black") +
  annotate("path", x=107.84-10*cos(seq(-0.3*pi,0.3*pi,length.out=30)), size = 0.6,
           y=40-10*sin(seq(-0.3*pi,0.3*pi,length.out=30)), col="black") +
  geom_point(data = fdj_shots, aes(x = location.x, y = location.y, fill = shot.statsbomb_xg, shape = shot.body_part.name),
             size = 6, alpha = 0.8) + 
  theme(axis.text.x=element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        plot.caption=element_text(size=13,family="Source Sans Pro", hjust=0.5, vjust=0.5),
        plot.subtitle = element_text(size = 18, family="Source Sans Pro", hjust = 0.5),
        axis.text.y=element_blank(),
        legend.position = "top",
        legend.title=element_text(size=22,family="Source Sans Pro"),
        legend.text=element_text(size=20,family="Source Sans Pro"),
        legend.margin = margin(c(20, 10, -85, 50)),
        legend.key.size = unit(1.5, "cm"),
        plot.title = element_text(margin = margin(r = 10, b = 10), face="bold",size = 32.5, family="Source Sans
Pro", colour = "black", hjust = 0.5),
        legend.direction = "horizontal",
        axis.ticks=element_blank(),
        aspect.ratio = c(65/100),
        plot.background = element_rect(fill = "white"),
        strip.text.x = element_text(size=13,family="Source Sans Pro")) +
  labs(title = "Frenkie de Jong, Shot Map", subtitle = "La Liga, 2020/21") + 
  scale_fill_gradientn(colours = shotmapxgcolors, limit = c(0,0.8), oob=scales::squish, name = "Expected Goals
Value") + 
  scale_shape_manual(values = c("Head" = 21, "Right Foot" = 23, "Left Foot" = 24), name ="") + #6
  guides(fill = guide_colourbar(title.position = "top"),
         shape = guide_legend(override.aes = list(size = 7, fill = "black"))) + 
  coord_flip(xlim = c(85, 125)) 

# Get Valuations ----
Liliga_valuations_20 <- get_player_market_values(country_name = "Spain",
                                                 start_year = 2020)
