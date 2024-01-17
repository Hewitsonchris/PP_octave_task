# Load necessary packages
library(jsonlite)
library(dplyr)
library(purrr)
library(tidyr)
library(ggplot2)


# Directory path where your json.gz files are located
# List all json.gz files in the folder
json_gz_files <- list.files( pattern = "\\.json\\.gz$", full.names = TRUE)

# Initialize an empty list to store the data
all_data <- list()

# Loop through each json.gz file and load its contents
for (file in json_gz_files) {
  # Read the data from the json.gz file
  data <- fromJSON(gzfile(file))
  # Store the data in the list
  all_data[[file]] <- data
}



# Initialize empty lists to store trials and target data
trials_list <- list()
targets_list <- list()

# Iterate through each subject's list in 'all_data' and separate 'trials' and 'target' data
for (i in seq_along(all_data)) {
  subject_data <- all_data[[i]]
  trials_list[[i]] <- subject_data$trials
  targets_list[[i]] <- subject_data$target
}

# create combined_df
combined_df <- bind_rows(Map(cbind, trials_list, target_list))

subject_sizes <- sapply(targets_list, function(x) dim(x)[1])
# Creating subject column based on subject_sizes
combined_df$subject <- rep(seq_along(subject_sizes), subject_sizes)
# Initialize an empty vector to store trial numbers
trial_numbers <- unlist(lapply(subject_sizes, function(size) seq_len(size)))

# Add the trial column to combined_df
combined_df$trial <- trial_numbers


# Remove rows where 'correct_flag' is NA
combined_df <- combined_df %>%
  filter(!is.na(correct_flag))

# Adjust trial numbers within each subject
combined_df <- combined_df %>%
  group_by(subject) %>%
  mutate(trial = row_number())

# Rename x, y, angle columns to target_x, target_y, target_angle
combined_df <- combined_df %>%
  rename(target_x = x, target_y = y, target_angle = angle)




############ PER SUBJECT RESPONSE STATS ################################################
# Calculate counts of correct and incorrect responses including subject numbers
response_counts_per_sub <- combined_df %>%
  group_by(subject, manipulation_angle, jump_angle, correct_flag) %>%
  summarize(count = n()) %>%
  ungroup()

# Calculate the total count for each (subject, manip_angle, jump_angle, target_number) combination
total_counts_per_sub <- response_counts_per_sub %>%
  group_by(subject, manipulation_angle, jump_angle) %>%
  summarize(total_count = sum(count))

# Calculate the percentage of correct responses for each subject
percentage_correct_per_sub <- response_counts_per_sub %>%
  filter(correct_flag == 1) %>%
  left_join(total_counts_per_sub, by = c("subject", "manipulation_angle", "jump_angle")) %>%
  mutate(percentage_correct = (count / total_count) * 100)



# Assuming your data frame is named percentage_correct_per_sub

summary_stats <- percentage_correct_per_sub %>%
  group_by(manipulation_angle, jump_angle) %>%
  summarise(mean_percentage = mean(percentage_correct, na.rm = TRUE),
            sd_percentage = sd(percentage_correct, na.rm = TRUE))

summary_stats$manipulation_angle <- unlist(summary_stats$manipulation_angle)
summary_stats$jump_angle <- unlist(summary_stats$jump_angle)



# Convert manipulation_angle to factor for color-coding
summary_stats$manipulation_angle <- factor(summary_stats$manipulation_angle)




# Plotting mean_percentage with sd_percentage as error bars, color-coded by manipulation_angle
ggplot(summary_stats, aes(x = factor(jump_angle), y = mean_percentage, color = manipulation_angle)) +
  geom_line(size = 1) +
  geom_errorbar(aes(ymin = mean_percentage - sd_percentage, ymax = mean_percentage + sd_percentage),
                width = 0.2, position = position_dodge(0.2)) +
  labs(x = "Jump Angle", y = "Mean Percentage", color = "Manipulation Angle") +
  theme_minimal() +
  geom_line(aes(group = manipulation_angle), position = position_dodge(0.2), linetype = "solid")




############ Group RESPONSE STATS ################################################
# Calculate counts of correct and incorrect responses
response_counts <- combined_df %>%
  group_by(manipulation_angle, jump_angle, correct_flag) %>%
  summarize(count = n()) %>%
  ungroup()

# Calculate the total count for each (manip_angle, jump_angle, target_number) combination
total_counts <- response_counts %>%
  group_by(manipulation_angle, jump_angle) %>%
  summarize(total_count = sum(count))

# Calculate the percentage of correct responses collapsing over subject
percentage_correct <- response_counts %>%
  filter(correct_flag == 1) %>%
  left_join(total_counts, by = c("manipulation_angle", "jump_angle")) %>%
  mutate(percentage_correct = (count / total_count) * 100)


percentage_correct$manipulation_angle <- as.numeric(percentage_correct$manipulation_angle)
percentage_correct$jump_angle <- as.numeric(percentage_correct$jump_angle)
percentage_correct$correct_flag <- as.numeric(percentage_correct$correct_flag)
percentage_correct$count <- as.numeric(percentage_correct$count)
percentage_correct$total_count <- as.numeric(percentage_correct$total_count)
percentage_correct$percentage_correct <- as.numeric(percentage_correct$percentage_correct)


ggplot(percentage_correct, aes(x = factor(jump_angle), y = percentage_correct, 
                               color = factor(manipulation_angle))) +
  geom_line(aes(group = interaction(manipulation_angle)), position = "dodge") +
  geom_errorbar(aes(ymin = percentage_correct - sd(percentage_correct), 
                    ymax = percentage_correct + sd(percentage_correct)),
                width = 0.2, position = position_dodge(0.2)) +
  labs(x = "Jump Angle", y = "Percentage Correct", color = "Manipulation Angle") +
  theme_minimal()


# Selecting required columns and arranging them in the specified order
PP_data <- combined_df %>%
  select(subject, trial, manipulation_angle, jump_angle, response_time, response,
         correct_response, correct_flag, target_angle, rt, mt, ep_reach_angle, diff_angle)


# Save the extracted_data as a CSV file
write.csv(pp_data, file = "pp_data.csv", row.names = FALSE)

