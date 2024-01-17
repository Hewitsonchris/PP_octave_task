library(dplyr)

# Extracting required columns
target_x <- dat_temp$target_x
target_y <- dat_temp$target_y
target_angle <- dat_temp$target_angle
id <- dat_temp$subject
trial <- dat_temp$trial
rt=dat_temp$rt
mt = dat_temp$mt
manipulation_angle = dat_temp$manip_angle
jump_angle = dat_temp$jump_angle
reach_angle = dat_temp$hand_angle
diff_angle = dat_temp$diff_angle
response = dat_temp$response
response_time = dat_temp$response_time
correct_response = dat_temp$correct_response
correct_flag = dat_temp$correct_flag

# Creating target_data data frame
target_data <- data.frame(
  id = id,
  trial = trial,
  target_x = target_x,
  target_y = target_y,
  target_angle = target_angle,
  rt = rt,
  mt = mt,
  manipulation_angle = manipulation_angle,
  jump_angle = jump_angle,
  reach_angle = reach_angle,
  diff_angle = diff_angle,
  response = response,
  response_time = response_time,
  correct_response = correct_response,
  correct_flag = correct_flag
  
)

target_data$id <- as.numeric(factor(target_data$id, levels = unique(target_data$id)))


# Calculate the counts per subject/trial combination in intention_movement_data
count_data <- move_data %>%
  group_by(subject, trial) %>%
  summarise(row_count = n())

# Merge target_data into count_data based on subject and trial
final_result <- count_data %>%
  left_join(target_data, by = c("subject" = "id", "trial")) %>%
  group_by(subject, trial) %>%
  slice(rep(1:n(), times = row_count)) %>%
  ungroup()

# Adding columns from final_result to intention_movement_data
movement_data <- move_data %>%
  mutate(
    target_x = final_result$target_x,
    target_y = final_result$target_y,
    target_angle = final_result$target_angle,
    rt = final_result$rt,
    mt = final_result$mt,
    manipulation_angle = final_result$manipulation_angle,
    jump_angle = final_result$jump_angle,
    reach_angle = final_result$reach_angle,
    diff_angle = final_result$diff_angle,
    response = final_result$response,
    response_time = final_result$response_time,
    correct_response = final_result$correct_response,
    correct_flag = final_result$correct_flag
  )


# Assuming intention_movement_data already exists

# Add the all_frames vector as a new column named "frames" to intention_movement_data
# Set seed for reproducibility
set.seed(123)

# Generate random values for frame_dur
movement_data$frame_dur <- rnorm(nrow(movement_data), mean = 0.000656326, sd = 0.000656326 * 0.01)




# Set the seed for reproducibility
set.seed(123)  # You can use any seed value

# Generate 19 random numbers following a normal distribution
random_numbers <- round(rnorm(20, mean = 2000, sd = 300))











set.seed(123)  # Set seed for reproducibility

# Initialize a vector to store frame numbers
all_frames <- numeric()

# Loop through each subject
for (subject in unique(count_data$subject)) {
  # Get the indices of trials for the current subject in count_data
  subject_trials <- which(count_data$subject == subject)
  
  # Get the starting frame for trial 1 for the subject
  trial_start_frame <- random_numbers[subject]
  
  # Loop through each trial for the subject
  for (i in subject_trials) {
    row_count <- count_data$row_count[i]
    
    # Generate frame numbers within the trial
    trial_frames <- seq(trial_start_frame, trial_start_frame + row_count - 1)
    
    # Append the trial frames to the vector storing all frames
    all_frames <- c(all_frames, trial_frames)
    
    # Update the trial start frame for the next trial based on the normal distribution
    trial_start_frame <- trial_frames[length(trial_frames)] + round(rnorm(1, mean = 1500, sd = 200))
  }
}


# Adding columns from final_result to intention_movement_data
movement_data <- movement_data %>%
  mutate(
    frames = all_frames
  )



library(dplyr)



# Assuming movement_data is your dataframe
movement_data$is_manipulated <- ifelse(movement_data$manipulation_angle != 0, 1, 0)
movement_data$online_feedback <- 0
movement_data$endpoint_feedback <- ifelse(movement_data$manipulation_angle != 0, 1, 0)
movement_data$is_judged <- 1  # Setting is_judged to 1 for all rows
movement_data$manipulation_type <- ifelse(movement_data$manipulation_angle != 0, 2, 0)

# Assuming movement_data is your dataframe
movement_data$was_restarted <- ifelse(movement_data$too_slow == 1, 1, 0)





library(dplyr)

# Assuming intention_movement_data exists with subject, trial, and state columns

movement_data <- movement_data %>%
  mutate(
    label = state
  )



