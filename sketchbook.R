
library(tidyverse)
library(reshape2)
library(forcats)

#  Read in data
bike_data <- read_csv("https://raw.githubusercontent.com/sventura/315-code-and-datasets/master/data/nyc-citi-bike-data-subset.csv")
date_time <- colsplit(bike_data$starttime, " ", c("date", "time"))

#  Add start_date variable to big_bike, and a bunch of other variables
bike_data <- mutate(bike_data,
                    time_of_day = as.vector(date_time$time),
                    start_date = as.Date(date_time$date, format = "%m/%d/%Y"),
                    birth_decade = paste0(substr(`birth year`, 1, 3), "0s"),
                    hour_of_day = as.integer(substr(time_of_day, 1, 2)),
                    am_or_pm = ifelse(hour_of_day < 12, "AM", "PM"),
                    day_of_week = weekdays(start_date),
                    less_than_30_mins = ifelse(tripduration < 1800, 
                                               "Short Trip", "Long Trip"),
                    less_than_15_mins = ifelse(tripduration < 1800, 
                                               "Less Than 15 Minutes", 
                                               "15 Minutes Or Longer"),
                    weekend = ifelse(day_of_week %in% c("Saturday", "Sunday"), 
                                     "Weekend", "Weekday"))

day_level <- c("Sunday", "Monday","Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
bike_data <- bike_data %>%
  mutate(
    day_of_week2 = factor(day_of_week,  day_level)
  )

ggplot(bike_data, aes(x = day_of_week)) + geom_bar()
ggplot(bike_data, aes(x = day_of_week2)) + geom_bar()


f <- factor(c("a", "b", "c", "d"))
fct_relevel(f)
fct_relevel(f, "c")
fct_relevel(f, "b", "a")


f <- (c("M", "Tu", "W", "Th", "F",
        "Sa", "Su"))
day_15 <- bike_data %>%
  mutate(
    day_of_week = factor(day_of_week, f)
  ) 

ggplot(day_15, aes(x=fct_relevel(day_of_week, f), fill = less_than_15_mins)) + 
  geom_bar(position = "fill") + 
  labs(title = "Proportions of Rides Greater than and Less than 15 Minutes")

day_15 <- bike_data %>%
  group_by(day_of_week, less_than_15_mins) %>%
  summarize(count = n())

#Using full bike_data
ggplot(bike_data, aes(x = fct_rev(fct_infreq(day_of_week)), fill = less_than_15_mins)) + 
  geom_bar(position = "dodge")+
  labs(
    title = "Day of the Week and Length of Bike Ride",
    x = "Day of Week",
    y = "Count"
  )


#  Fourth Down Data from Greg
fourthDowns.train = playData.train[which(playData.train$down == "4"),]    
dim(fourthDowns.train) # = 19889   19 
fourthDowns.train = fourthDowns.train[, c("down", "ydstogo", "yrdline100", "TimeSecs", "ScoreDiff", 
                                          "OffensiveTimeouts", "DefensiveTimeouts", "PlayType", "WPA.train", "posteam")]

fourthDowns.test = playData.test[which(playData.test$down== "4"),]
# [1] 4193   19
fourthDowns.test = fourthDowns.test[, c("down", "ydstogo", "yrdline100", "TimeSecs", "ScoreDiff", 
                                        "OffensiveTimeouts", "DefensiveTimeouts", "PlayType", "WPA.test", "posteam")]


#  Create is_pass, is_rush, etc variables for training and testing data
fourthDowns.train <- fourthDowns.train %>%
  filter(PlayType %in% c("Pass", "Run", "Field Goal", "Punt")) %>%
  mutate(is_pass = 1 * (PlayType == "Pass"),
         is_run = 1 * (PlayType == "Run"),
         is_fg = 1 * (PlayType == "Field Goal"),
         is_punt = 1 * (PlayType == "Punt")) %>%
  rename(WPA = WPA.train)

fourthDowns.test <- fourthDowns.test %>%
  filter(PlayType %in% c("Pass", "Run", "Field Goal", "Punt")) %>%
  mutate(is_pass = 1 * (PlayType == "Pass"),
         is_run = 1 * (PlayType == "Run"),
         is_fg = 1 * (PlayType == "Field Goal"),
         is_punt = 1 * (PlayType == "Punt")) %>%
  rename(WPA = WPA.test)


#  Plots
library(gridExtra)
yards_to_go <- ggplot(fourthDowns.train, aes(x = ydstogo, y = WPA, color = PlayType)) + 
  geom_point(alpha = 0.25) + geom_smooth(size = 2) + ylim(-0.25, 0.25) + 
  theme_bw() + labs(title = "WPA vs. Yards to Go, by Play Type",
                    subtitle = "Fourth Down Plays, 2011-2015")

yard_line <- ggplot(fourthDowns.train, aes(x = yrdline100, y = WPA, color = PlayType)) + 
  geom_point(alpha = 0.25) + geom_smooth(size = 2) + ylim(-0.25, 0.25) + 
  theme_bw() + labs(title = "WPA vs. Yard Line, by Play Type",
                    subtitle = "Fourth Down Plays, 2011-2015")

x <- grid.arrange(yards_to_go, yard_line)
ggsave(x, filename = "/Users/sam/Dropbox/Football/armchair analysis data/Archive/ExploratoryGraphs.pdf", 
       height = 10, width = 10)


#  Build series of models for each place on the field
fourth_lm <- lm(WPA ~ is_pass + is_run + is_fg + is_punt,
                data = filter(fourthDowns.train, yrdline100 > 60))
summary(fourth_lm)

fourth_lm <- lm(WPA ~ is_pass + is_run + is_fg + is_punt,
                data = filter(fourthDowns.train, 
                              yrdline100 <= 60, yrdline100 > 50))
summary(fourth_lm)

fourth_lm <- lm(WPA ~ is_pass + is_run + is_fg + is_punt,
                data = filter(fourthDowns.train, 
                              yrdline100 <= 50, yrdline100 > 40))
summary(fourth_lm)

fourth_lm <- lm(WPA ~ is_pass + is_run + is_fg + is_punt,
                data = filter(fourthDowns.train, 
                              yrdline100 <= 40, yrdline100 > 30))
summary(fourth_lm)

fourth_lm <- lm(WPA ~ is_pass + is_run + is_fg + is_punt,
                data = filter(fourthDowns.train, 
                              yrdline100 <= 30, yrdline100 > 20))
summary(fourth_lm)

fourth_lm <- lm(WPA ~ is_pass + is_run + is_fg + is_punt,
                data = filter(fourthDowns.train, 
                              yrdline100 <= 20, yrdline100 > 10))
summary(fourth_lm)

fourth_lm <- lm(WPA ~ is_pass + is_run + is_fg + is_punt,
                data = filter(fourthDowns.train, 
                              yrdline100 <= 10))
summary(fourth_lm)




set.seed(3951824)
# Table of counts (contingency)
X <- sample(letters[1:3], 100, 1)
Y <- sample(letters[4:5], 100, 1)
t  <- table(X,Y)
tp  <- t/100 # proportions
tn  <- tp/sum(tp)     # normalized, joints
p_x <- rowSums(tn)    # marginals
p_y <- colSums(tn)

P <- tn 
Q <- p_x %o% p_y 

# P(X, Y)   : bin frequency: P_i
# P(X) P(Y) : bin frequency, Q_i 
mi <- sum(P*log(P/Q))
library(entropy)
mi.empirical(t) == mi

freqs1 <- table(sample(letters, 10000, prob = 1:26, replace = T))
freqs2 <- table(sample(letters, 10000, prob = 26:1, replace = T))

KL.plugin(freqs1, freqs2)
chi2.plugin(freqs1, freqs2)
pchisq(2.05, df = 10)



library(MASS)
data(Cars93)
var <- bike_data$day_of_week  # the categorical data 

## Prep data (nothing to change here)
nrows <- 20
df <- expand.grid(y = 1:nrows, x = 1:nrows)
categ_table <- floor(table(var) / length(var) * (nrows*nrows))
categ_table
#>   2seater    compact    midsize    minivan     pickup subcompact        suv 
#>         2         20         18          5         14         15         26 

temp <- rep(names(categ_table), categ_table)
df$category <- sort(c(temp, sample(names(categ_table), nrows^2 - length(temp), prob = categ_table)))
# NOTE: if sum(categ_table) is not 100 (i.e. nrows^2), it will need adjustment to make the sum to 100.

## Plot
ggplot(df, aes(x = x, y = y, fill = category)) + 
  geom_tile(color = "black", size = 0.5) +
  scale_x_continuous(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  scale_fill_brewer(palette = "Set3") +
  labs(title="Waffle Chart of Day of Week",
       caption="Source:  NYC Citi Bike Dataset", 
       x = NULL, y = NULL) + 
  theme_bw()


#  Set up data to create the waffle chart
library(MASS)
data(Cars93)
var <- Cars93$Type  # the categorical variable you want to plot 
nrows <- 9  #  the number of rows in the resulting waffle chart
categ_table <- floor(table(var) / length(var) * (nrows*nrows))
temp <- rep(names(categ_table), categ_table)
df <- expand.grid(y = 1:nrows, x = 1:nrows) %>%
  mutate(category = sort(c(temp, sample(names(categ_table), 
                                        nrows^2 - length(temp), 
                                        prob = categ_table))))
# NOTE: if sum(categ_table) is not nrows^2, it will need adjustment to make the sum = nrows^2.

#  Make the Waffle Chart
ggplot(df, aes(x = x, y = y, fill = category)) + 
  geom_tile(color = "black", size = 0.5) +
  scale_x_continuous(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  scale_fill_brewer(palette = "Set3") +
  labs(title="Waffle Chart of Car Type",
       caption="Source:  Cars93 Dataset", 
       fill = "Car Type",
       x = NULL, y = NULL) + 
  theme_bw()



#  Set up data to create the waffle chart
var <- imdb$content_rating  # the categorical data 
nrows <- 25  #  the number of rows in the resulting waffle chart
categ_table <- floor(table(var) / length(var) * (nrows*nrows))
temp <- rep(names(categ_table), categ_table)
df <- expand.grid(y = 1:nrows, x = 1:nrows) %>%
  mutate(category = sort(c(temp, sample(names(categ_table), 
                                        nrows^2 - length(temp), 
                                        prob = categ_table))))
# NOTE: if sum(categ_table) is not nrows^2, it will need adjustment to make the sum = nrows^2.

#  Make the Waffle Chart
ggplot(df, aes(x = x, y = y, fill = category)) + 
  geom_tile(color = "black", size = 0.5) +
  scale_x_continuous(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  scale_fill_brewer(palette = "Set3") +
  labs(title="Waffle Chart of Car Type",
       caption="Source:  Cars93 Dataset", 
       fill = "Car Type",
       x = NULL, y = NULL) + 
  theme_bw()



#  Waffle charts
var <- imdb$content_rating  # the categorical data 
nrows <- 20
df <- expand.grid(y = 1:nrows, x = 1:nrows)
categ_table <- floor(table(var) / length(var) * (nrows*nrows))
temp <- rep(names(categ_table), categ_table)
df$category <- sort(c(temp, sample(names(categ_table), nrows^2 - length(temp), prob = categ_table)))
# NOTE: if sum(categ_table) is not nrows^2, it will need adjustment to make the sum = nrows^2.

## Plot
ggplot(df, aes(x = x, y = y, fill = category)) + 
  geom_tile(color = "black", size = 0.5) +
  scale_x_continuous(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  scale_fill_brewer(palette = "Set3") +
  labs(title="Waffle Chart of Day of Week",
       caption="Source:  NYC Citi Bike Dataset", 
       x = NULL, y = NULL) + 
  theme_bw()







devtools::install_github("yeukyul/lindia", force = TRUE)
library(lindia)
library(MASS)
data(Cars93)

model <- lm(Price ~ Passengers + Fuel.tank.capacity, data = Cars93)
gg_diagnose(model)
gg_resfitted(model)
gg_resX(model)
gg_reshist(model)
gg_boxcox(model)
gg_qqplot(model)
?gg_diagnose



library(tidyverse)
food <- read_csv("https://raw.githubusercontent.com/sventura/315-code-and-datasets/master/data/food-facts.csv")
food


ggplot(food, aes(y = energy_100g, x = fat_100g, color = nutrition_grade_fr,
                 size = proteins_100g)) + 
  geom_point() + 
  labs(
    title = "my title",
    subtitle = "sub",
    color = "this is my new legend title",
    size = "amount of protein"
  ) + scale_x_sqrt() + 
  scale_y_sqrt()





library(datasets)
data("geyser")
head(geyser)
head(mutate(geyser, 
            lag1 = dplyr::lag(duration, 1),
            lag2 = dplyr::lag(duration, 2),
            lag3 = dplyr::lag(duration, 3),
            lead1 = dplyr::lead(duration, 1)
            ))


options(tibble.width = Inf)
set.seed(10)
shark <- read_csv("https://raw.githubusercontent.com/sventura/315-code-and-datasets/master/data/attacks_test.csv")
shark <- mutate(shark, 
                SharkLength = rpois(nrow(shark), 10),
                SharkLength = ifelse(SharkLength < 4, rpois(nrow(shark), 4) + 4,
                                     SharkLength))
write.csv(shark, "/Users/sam/Desktop/CMU-VAP/315/315-code-and-datasets/315-code-and-datasets/data/shark-attacks-spring-2017.csv")
ggplot(shark, aes(x = Year, y = SharkLength)) +
  geom_point() + geom_smooth(method = lm)



install.packages("hrbrthemes")
library(hrbrthemes)
library(MASS)
data(Cars93)

my_plot <- ggplot(Cars93, aes(x = Fuel.tank.capacity, y = Price)) + geom_point() + 
  labs(
    title = "statitsical",
    subtitle = "grahpics",
    x = "adn",
    y = "vizualisation"
  )

gg_check(my_plot)



library(tidyverse)
library(forcats)

options(tibble.width = Inf)
olive <- read_csv("https://raw.githubusercontent.com/sventura/315-code-and-datasets/master/data/olive_oil.csv")
olive <- mutate(olive, area = as.character(area), region = as.character(region))

#  IMDB -- Pre-test
imdb <- read_csv("/Users/sam/Downloads/movie_metadata.csv") %>%
  select(color, num_critic_for_reviews, duration, gross, genres, movie_title, 
         num_voted_users, cast_total_facebook_likes, language, country, 
         content_rating, budget, title_year, imdb_score, aspect_ratio, 
         movie_facebook_likes) %>%
  filter(content_rating %in% c("R", "PG-13", "PG", "G", "NC-17"),
         content_rating %in% c("R", "PG-13", "PG", "G", "Not Rated", "NC-17"),
         #country %in% c("USA", "UK", "Germany", "France", "Canada", "Australia"),
         #country %in% c("USA", "UK", "Germany", "France", "Canada", "Australia"),
         country %in% c("USA", "UK", "Germany", "France", "Canada"),
         !is.na(language),
         !is.na(content_rating)) %>%
  mutate(language = ifelse(language == "English", "English", "Other"),
         movie_title = gdata::trim(movie_title)) %>%
  filter(movie_title != "Frat Party",
         #movie_title != "This Is Martin Bonner",
         movie_title != "Indie Game: The Movie") %>%
  arrange(desc(aspect_ratio))
imdb
write.csv(imdb, "/Users/sam/Desktop/CMU-VAP/315/315-code-and-datasets/315-code-and-datasets/data/imdb_pretest.csv")


#  IMDB -- Test
imdb <- read_csv("/Users/sam/Downloads/movie_metadata.csv") %>%
  dplyr::select(color, num_critic_for_reviews, duration, gross, genres, movie_title, 
         num_voted_users, cast_total_facebook_likes, language, country, 
         content_rating, budget, title_year, imdb_score, aspect_ratio, 
         movie_facebook_likes) %>% 
  mutate(content_rating = ifelse(content_rating %in% c("Unrated", "Not Rated") |
                                   is.na(content_rating), 
                                 "N/A or Unrated", content_rating),
         content_rating = ifelse(content_rating %in% c("Approved", "Passed", 
                                                       "G", "TV-G", "GP"), 
                                 "Validated for All Ages (G)", content_rating)) %>%
  filter(content_rating %in% c("R", "PG-13", "PG", "Validated for All Ages (G)", 
                               "N/A or Unrated", "NC-17"),
         country %in% c("USA", "UK", "Germany", "France", "Australia")) %>%
  mutate(language = ifelse(language != "English" | is.na(language), 
                           "N/A or Other", "English"),
         movie_title = gdata::trim(movie_title)) %>%
  filter(movie_title != "This Is Martin Bonner") %>%
  arrange(desc(aspect_ratio))
imdb
write.csv(imdb, "/Users/sam/Desktop/CMU-VAP/315/315-code-and-datasets/315-code-and-datasets/data/imdb_test.csv")

imdb <- mutate(imdb, is_comedy = grepl(pattern = "Comedy", x = genres),
               is_action = grepl(pattern = "Action", x = genres))
ggplot(imdb, aes(x = aspect_ratio)) + geom_histogram() + xlim(1, 4.2)
ggplot(imdb, aes(x = content_rating)) + geom_bar() + coord_flip()
ggplot(imdb, aes(x = content_rating, fill = is_action)) + geom_bar() + coord_flip()

ggplot(imdb, aes(x = duration, y = gross)) + geom_point() + 
  geom_smooth(method = lm)

ggplot(imdb, aes(x = title_year, y = aspect_ratio)) + geom_point() + 
  geom_smooth()

ggplot(imdb, aes(x = title_year, y = duration)) + geom_point() + 
  geom_smooth()

ggplot(imdb, aes(x = imdb_score, y = num_voted_users)) + geom_point() + 
  geom_smooth()

ggplot(imdb, aes(x = budget, y = gross)) + geom_point() + 
  geom_smooth()

ggplot(imdb, aes(x = log(budget + 1), y = imdb_score, color = content_rating)) + 
  geom_point() + geom_smooth(method = lm)

ggplot(imdb, aes(x = duration, color = language)) + geom_density()

imdb <- mutate(imdb, 
               profit = gross - budget, 
               is_action = grepl(pattern = "Action", x = genres),
               is_romance = grepl(pattern = "Romance", x = genres),
               is_comedy = grepl(pattern = "Comedy", x = genres))

ggplot(imdb, aes(x = imdb_score, y = profit, color = is_action)) + 
  geom_point() + geom_smooth()

ggplot(imdb, aes(x = title_year, y = profit)) + 
  geom_point(aes(color = country)) + 
  geom_smooth(method = lm, color = "black", size = 2) + 
  geom_smooth(data = filter(imdb, country == "France", title_year > 1990), 
              method = lm, color = "red", size = 2)


table1 <- table(imdb$content_rating, imdb$is_comedy)
chisq.test(table1)
chisq.test(imdb$content_rating, imdb$is_comedy)

#  Mid-Semester Grades
#  Multiple Choice
library(gsheet)
mc <- as_data_frame(gsheet2tbl("https://docs.google.com/spreadsheets/d/1PMa30fRKYxaj9I-7wgp4wcEFJqszBhKeMz4eJdfguTI/pub?gid=1929804628&single=true&output=csv"))
names(mc)
perfect <- filter(mc, andrew == "perfect")
answers_b <- unique(unlist(strsplit(mc$b, ", ")))
answers_c <- unique(unlist(strsplit(mc$c, ", ")))
answers_d <- unique(unlist(strsplit(mc$d, ", ")))
answers_e <- unique(unlist(strsplit(mc$e, ", ")))

correct_b <- unique(unlist(strsplit(perfect$b, ", ")))
correct_c <- unique(unlist(strsplit(perfect$c, ", ")))
correct_d <- unique(unlist(strsplit(perfect$d, ", ")))
correct_e <- unique(unlist(strsplit(perfect$e, ", ")))

wrong_b <- setdiff(answers_b, correct_b)
wrong_c <- setdiff(answers_c, correct_c)
wrong_d <- setdiff(answers_d, correct_d)
wrong_e <- setdiff(answers_e, correct_e)


mc <- mutate(mc, 
  score_a = 5 * (a == perfect$a),
  
  student_b = strsplit(b, ", "),
  good_b = sapply(student_b, intersect, correct_b),
  good_b = sapply(good_b, length),
  bad_b = sapply(student_b, intersect, wrong_b),
  bad_b = sapply(bad_b, length),
  score_b = good_b + (5 - length(correct_b) - bad_b),
  
  student_c = strsplit(c, ", "),
  good_c = sapply(student_c, intersect, correct_c),
  good_c = sapply(good_c, length),
  bad_c = sapply(student_c, intersect, wrong_c),
  bad_c = sapply(bad_c, length),
  score_c = good_c + (5 - length(correct_c) - bad_c),
  
  student_d = strsplit(d, ", "),
  good_d = sapply(student_d, intersect, correct_d),
  good_d = sapply(good_d, length),
  bad_d = sapply(student_d, intersect, wrong_d),
  bad_d = sapply(bad_d, length),
  score_d = good_d + (5 - length(correct_d) - bad_d),
  
  student_e = strsplit(e, ", "),
  good_e = sapply(student_e, intersect, correct_e),
  good_e = sapply(good_e, length),
  bad_e = sapply(student_e, intersect, wrong_e),
  bad_e = sapply(bad_e, length),
  score_e = good_e + (5 - length(correct_e) - bad_e),
  
  missed_a = 5 - score_a,
  missed_b = 5 - score_b, 
  missed_c = 5 - score_c, 
  missed_d = 5 - score_d, 
  missed_e = 5 - score_e, 
  
  total = score_a + score_b + score_c + score_d + score_e,
  missed = 25 - total,
  andrew = gdata::trim(andrew)) %>% 
  select(name, andrew, total, missed) %>%
  arrange(andrew)

write.csv(mc, file = "/Users/sam/Desktop/CMU-VAP/315/36-315 Spring 2017 Lab Exam Multiple Choice Grades.csv")




imdb <- mutate(imdb, 
               content_rating = factor(content_rating, 
                                       levels = c("Validated for All Ages (G)", 
                                                  "PG","PG-13", "R", "NC-17", 
                                                  "N/A or Unrated"),
                                       labels=c("Validated for All Ages (G)", 
                                                "Parental Guidance (PG)", 
                                                "Parental Guidance under 13 (PG-13)", 
                                                "Restricted under 17 (R)", 
                                                "No Children under 17 (NC-17)", 
                                                "Rating Not Available")))


imdb <- mutate(imdb, 
               content_rating = factor(content_rating, 
                                       levels = c("Validated for All Ages (G)", 
                                                  "PG","PG-13", "R", "NC-17", 
                                                  "N/A or Unrated"),
                                       labels=c("Validated for All Ages (G)", 
                                                "Parental Guidance (PG)", 
                                                "Parental Guidance under 13 (PG-13)", 
                                                "Restricted under 17 (R)", 
                                                "No Children under 17 (NC-17)", 
                                                "Rating Not Available")))
ggplot(imdb, aes(x = budget, title_year)) + geom_point() + 
  facet_grid(. ~ content_rating, margins = TRUE)


ggplot(imdb, aes(x = budget, title_year)) + geom_point(aes(shape = color))

ggplot(imdb, aes(x = budget, title_year)) + geom_point(aes(shape = color)) + 
  scale_shape_manual(values = c("Black and White" = "BW", 
                                "Color" = "C")) + 
  scale_shape_manual(values = c("Above-7" = "A", 
                               "Under-7" = "U"))



student_mds <- read_csv("https://raw.githubusercontent.com/sventura/315-code-and-datasets/master/data/students.csv") %>%
  dplyr::select(RaisedHands, VisitedResources, AnnouncementsView, Discussion) %>%
  scale %>% dist %>% cmdscale(k = 2) %>% as_data_frame

ggplot(student_mds, aes(x = V1, y = V2)) + geom_density2d(h = c(1/2, 1/2))




# comparisons are the comparisons
x <- comparisons %>% nest(-c(passid, blockid))
# x is a tibble, but we can think of it like a list of three elements, a block id, a pass id and a dataset for each unique block/pass combo

x$passid[1] might be first3last3
x$blockid[1] might be kayfri
x$data[1] might be id1 id2 first-jaro last-jaro etc.

# raw records
id.records <- read.csv("Robin-Syria-Data/records-id-2014.csv", stringsAsFactors = FALSE)
# i initialize all of the quid_kaylas with NA… this is important
id.records$uid_kayla <- NA
length(x$data)

for(i in 1:length(x$data)){
  
  z <- HclustCutGLM(x$data[[i]], x$blockid[i], x$passid[i], glm.mod, .5)
  # if(any(is.na(z$uids))) print(z$uids)
  
  nas <- is.na(id.records$uid_kayla[as.numeric(z$record.ids)])
  # print(non.nas)
  
  if(all(nas)){
    id.records$uid_kayla[as.numeric(z$record.ids)] <- z$uids
  }else{
    old.ids <- id.records$uid_kayla[as.numeric(z$record.ids)][which(!nas)]
    
    for(j in 1:length(old.ids)){
      id.records$uid_kayla[which(id.records$uid_kayla == old.ids[j])] <- z$uids[which(!nas)][j]
      old.ids <- id.records$uid_kayla[as.numeric(z$record.ids)][which(!nas)]
    }
    id.records$uid_kayla[as.numeric(z$record.ids)] <- z$uids
  }
}



student %>% dplyr::select(RaisedHands, VisitedResources, 
                          AnnouncementsView, Discussion) %>%
  scale %>% dist %>% hclust %>% as.dendrogram %>%
  dendextend::set("labels", student$AbsentDays, order_value = TRUE) %>%
  ggplot(theme = theme_bw(), horiz = T) + labs(title = "Student Similarity", y = "Pairwise Euclidean Distance")


colorblind_palette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", 
                        "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

get_colors <- function(x, palette = colorblind_palette) palette[match(x, unique(x))]

dend <- student %>% dplyr::select(RaisedHands, VisitedResources, 
                                  AnnouncementsView, Discussion) %>% 
  scale %>% dist %>% hclust %>% as.dendrogram %>% 
  dendextend::set("labels", student$AbsentDays, order_value = TRUE) %>% 
  dendextend::set("labels_col", get_colors(student$AbsentDays), order_value = TRUE) %>%
  dendextend::set("labels_cex", .5) %>%
  dendextend::set("branches_lwd",.7)

ggplot(dend, theme = theme_bw(), horiz = TRUE) + 
  labs(x = "") +
  theme(axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())



Cars93 %>% group_by(Type, Origin, Passengers) %>%
  summarize(count = n())


cars_cont <- dplyr::select(Cars93, Price, MPG.city, MPG.highway, EngineSize, 
                           Horsepower, RPM, Fuel.tank.capacity, Passengers,
                           Length, Wheelbase, Width, Turn.circle, Weight)

test1 <- cars_cont %>% scale %>% cor %>% abs * -1 + 1
test1 %>% as.dist %>% hclust %>% as.dendrogram %>% ggplot(horiz = T)

test2 <- cars_cont %>% cor %>% abs * -1 + 1
test2 %>% as.dist %>% hclust %>% as.dendrogram %>% ggplot(horiz = T)


library(MASS)
library(tidyverse)
data(Cars93)
cars_cont <- dplyr::select(Cars93, Price, MPG.city, MPG.highway, EngineSize, 
                           Horsepower, RPM, Fuel.tank.capacity, Passengers,
                           Length, Wheelbase, Width, Turn.circle, Weight)
scaled_cars_cont <- scale(cars_cont)
dist_cars <- dist(scaled_cars_cont, method = "euclidean")
hc_cars <- hclust(dist_cars, method = "average")
dend_cars <- as.dendrogram(hc_cars)
plot_cars <- ggplot(dend_cars, theme = theme_bw())
plot_cars

library(MASS)
library(tidyverse)
data(Cars93)
cars_cont <- dplyr::select(Cars93, Price, MPG.city, MPG.highway, EngineSize, 
                           Horsepower, RPM, Fuel.tank.capacity, Passengers,
                           Length, Wheelbase, Width, Turn.circle, Weight)
plot_cars <- ggplot(as.dendrogram(hclust(dist(scale(cars_cont), method = "euclidean"), method = "average")), theme = theme_bw())
plot_cars


library(MASS)
library(tidyverse)
data(Cars93)
plot_cars <- Cars93 %>% 
  dplyr::select(Price, MPG.city, MPG.highway, EngineSize, 
                Horsepower, RPM, Fuel.tank.capacity, Passengers,
                Length, Wheelbase, Width, Turn.circle, Weight) %>%
  scale %>%
  dist(method = "euclidean") %>%
  hclust(method = "average") %>%
  as.dendrogram %>%
  ggplot(theme = theme_bw())




library(tidyverse)
library(ggmap)
world_data <- map_data("world")

as_data_frame(world_data)

world_data <- world_data %>% left_join(adult,)
ggplot(world_data) + geom_polygon(aes(x = long, y = lat, group = group))


library(tidytext)
loan <- data.frame(desc = as.character(Cars93$Manufacturer))
description <- data_frame(desc = as.character(loan$desc))
loan_words <- description %>%
  unnest_tokens(word, desc)






library(tidyverse)
library(dendextend)
adult <- read_csv("https://raw.githubusercontent.com/chuqwang/315project/master/adult_2.csv")
country_level_adult <- adult %>%
  group_by(native.country) %>%
  summarize(count=n(),
            hours_per_week = mean(hours.per.week), 
            capital_gain = mean(capital.gain),
            capital_loss = mean(capital.loss),
            age = mean(age))
country_level_adult %>%
  select(-native.country) %>%
  scale %>% dist %>% hclust %>% as.dendrogram %>%
  set("labels", country_level_adult$native.country, order_value = T) %>%
  ggplot(horiz = T)







spew <- read_csv("/Users/sam/Downloads/people_42049000900.csv")
spew %>% 
  filter(!is.na(SCHG)) %>%
  mutate(college = ifelse(SCHG %in% c(15, 16), "college", "K-12")) %>%
  ggplot(aes(x = as.integer(AGEP), fill = college)) + geom_bar() + 
  labs(
    title = "AGEP by Level of School",
    subtitle = "SPEW Data for one PA tract",
    fill = "Level of School"
  )

acs <- read_csv("/Users/sam/Downloads/csv_ppa/ss13ppa.csv")
#acs <- ACS
acs %>%
  select(AGEP, SCHG) %>%
  filter(!is.na(SCHG)) %>%
  mutate(college = ifelse(SCHG %in% c(15, 16), "college", "K-12")) %>%
  ggplot(aes(x = as.integer(AGEP), fill = college)) + geom_bar() + 
  labs(
    title = "AGEP by Level of School",
    subtitle = "ACS Data for all of PA",
    fill = "Level of School"
  )



#  Static Graphics Poster Grades
options(tibble.width = Inf)
library(tidyverse)
grades <- read_csv("/Users/sam/Downloads/Spring 2017 -- 36-315 Poster Presentation Scoring (Responses) - Form Responses 1.csv")
names(grades) <- c("time", "group", "name", "data", "graph_explain", 
                   "graph_takeaways", "poster", "communication", 
                   "teamwork", "followup", "good", "bad", "comments")

grades <- grades %>%
  mutate(overall = data + graph_explain + graph_takeaways + poster + 
           communication + teamwork + followup)

grades %>% 
  group_by(group) %>%
  summarize(overall = mean(overall),
            count = n()) %>%
  arrange(desc(overall))

grades %>% 
  group_by(group) %>%
  summarize(poster = mean(poster),
            count = n()) %>%
  arrange(desc(poster))

grades %>% 
  group_by(group) %>%
  summarize(graph = mean(graph_explain + graph_takeaways),
            count = n()) %>%
  arrange(desc(graph))

grades %>% 
  group_by(group) %>%
  summarize(teamwork = mean(teamwork),
            count = n()) %>%
  arrange(desc(teamwork))

grades %>% 
  group_by(group) %>%
  summarize(followup = mean(followup),
            count = n()) %>%
  arrange(desc(followup))



rents <- read_csv("https://raw.githubusercontent.com/sventura/315-code-and-datasets/master/data/price.csv")
map_df <- map_data("state")
names(rents)[names(rents) == "State"] <- "region"
names(rents)[names(rents) == "January 2017"] <- "price"
rents <- dplyr::select(rents, region, price)
rents <- mutate(rents, region = tolower(region))
full_map_df <- left_join(map_df, rents, by = c("region" = "region"))
p3 <- ggplot(full_map_df, aes(x = long, y = lat, group = group, fill = price))
p3 <- p3 + geom_polygon() + labs(title = "Rent by State")+ 
  scale_fill_gradient2(low = "yellow", high = "red", 
                       mid = "orange", midpoint = 60, name = "Rent Price") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.title.y=element_blank(), legend.position = "bottom")
p3


map <- get_map(location = 'United States', zoom = 4)
mapPoints <- ggmap(map) +
  geom_point(aes(x = lon, y = lat, size = flights, color = DST), 
             data = airportA, alpha = .5)
mapPointsLegend <- mapPoints +
  scale_size_area(breaks = sqrt(c(1, 5, 10, 50, 100, 500)), 
                  labels = c(1, 5, 10, 50, 100, 500), 
                  name = "arriving routes")
LAXcode <- "LAX"
LAX <- filter(routes, 
              sourceAirport == LAXcode | 
                destinationAirport == LAXcode) %>%
  mutate(sourceAirportID = as.integer(sourceAirportID),
         destinationAirportID = as.integer(destinationAirportID))
LAXSource <- left_join(LAX, airports, by = c("sourceAirportID" = "ID"))
LAXDest <- left_join(LAX, airports, by = c("destinationAirportID" = "ID"))
LAXfull <- left_join(x = LAXSource, y = LAXDest, by = c("sourceAirportID" = "destinationAirportID"))
mapPointsLegend <- mapPointsLegend + 
  geom_segment(aes(x = lon.x, y = lat.x, xend = lon.y, 
                   yend = lat.y), data = LAXfull)
mapPointsLegend


temp <- my_list %>% unlist %>% as.factor %>% as.integer
relist(temp, skeleton = my_list)

graph_from_adj_list(relist(as.integer(as.factor(unique(unlist(my_list)))), skeleton = my_list))

list2 <- vector("list", length(unique(temp)))
for (ii in 1:length(my_list)) {
  for (jj in 1:length(my_list[[ii]])) {
    list2[my_list[[ii]][jj]] <- my_list[[ii]]
  }
}






