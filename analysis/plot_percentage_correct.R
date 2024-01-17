# Group by subject, manip_angle, and jump_angle, calculate percentage of 'correct' flags
percentage_correct <- dat %>%
  group_by(subject, manip_angle, jump_angle) %>%
  summarise(
    percentage_correct = mean(correct_flag == 'correct') * 100
  ) %>%
  ungroup()

# Group by subject, manip_angle, and jump_angle, calculate percentage of 'correct' flags
mean_percentage_correct <- dat %>%
  group_by(manip_angle, jump_angle) %>%
  summarise(
    percentage_correct = mean(correct_flag == 'correct') * 100
  ) %>%
  ungroup()

# Calculate standard deviation of percentage correct across subjects for each combo
sd_percentage_correct <- percentage_correct %>%
  group_by(manip_angle, jump_angle) %>%
  summarise(
    sd_percentage = sd(percentage_correct)
  ) %>%
  ungroup()




# Create a new data frame with the desired column order
temp <- data.frame(
  manip_angle = mean_percentage_correct$manip_angle,
  jump_angle = mean_percentage_correct$jump_angle,
  mean = mean_percentage_correct$percentage_correct,
  sd = sd_percentage_correct$sd_percentage
)


library(ggplot2)

# Plotting mean and sd for each manip_angle
ggplot(temp, aes(x = jump_angle, y = mean, group = manip_angle, color = factor(manip_angle))) +
  geom_line() +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.1) +
  labs(
    x = "Jump Angle",
    y = "Mean Percentage Correct",
    title = "Mean and SD for Each Manipulation Angle"
  ) +
  theme_minimal() +
  theme(legend.position = "top")
