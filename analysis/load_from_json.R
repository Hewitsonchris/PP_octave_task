# Load JSON files into a list
data_files <- list.files('./', pattern = '\\.json\\.gz$', full.names = TRUE)
loaded_data <- lapply(data_files, function(file) jsonlite::fromJSON(gzfile(file)))



# Preallocate the combined_data data frame
combined_data <- data.frame(
  subject = numeric(),
  trial = numeric(),
  is_manipulated = double(),
  manipulation_angle = double(),
  rt = double(),
  mt = double(),
  ep_reach_angle = double(),
  diff_angle = double(),
  av_clamp = double(),
  x = double(),
  y = double(),
  target_angle = double(),
  stringsAsFactors = FALSE
)

# Loop through each subject's data
for (i in seq_along(loaded_data)) {
  subject_data <- loaded_data[[i]]
  
  # Extract target data
  target_x <- subject_data$target$x
  target_y <- subject_data$target$y
  target_angle <- subject_data$target$angle
  
  is_manipulated <- subject_data$trials$manipulation_type
  manipulation_angle <- subject_data$trials$manipulation_angle
  rt <- subject_data$trials$rt
  mt <- subject_data$trials$mt
  ep_reach_angle <- subject_data$trials$ep_reach_angle
  diff_angle <- subject_data$trials$diff_angle
  av_clamp <- subject_data$trials$av_clamp
  
  for (trial_num in seq_along(target_x)) {
    dist_exceeded_index <- which(subject_data$cursor$label[[trial_num]] != "REACH")
    
    if (length(dist_exceeded_index) > 0) {
      x_values <- subject_data$cursor$x[[trial_num]][dist_exceeded_index]
      y_values <- subject_data$cursor$y[[trial_num]][dist_exceeded_index]
      
      target_angle_value <- target_angle[[trial_num]]
      is_manip <- as.double(is_manipulated[[trial_num]])
      manip_angle <- as.double(manipulation_angle[[trial_num]])
      react <- as.double(rt[[trial_num]])
      move <- as.double(mt[[trial_num]])
      ep <- as.double(ep_reach_angle[[trial_num]])
      diff <- as.double(diff_angle[[trial_num]])
      av <- as.double(av_clamp[[trial_num]])
      
      # Create a temporary data frame for the current row
      row_data <- data.frame(
        subject = i,
        trial = trial_num,
        is_manipulated = is_manip,
        manipulation_angle = manip_angle,
        rt = react,
        mt = move,
        ep_reach_angle = ep,
        diff_angle = diff,
        av_clamp = av,
        x = x_values,
        y = y_values,
        target_angle = target_angle_value,
        stringsAsFactors = FALSE
      )
      
      # Bind the row_data to combined_data
      combined_data <- rbind(combined_data, row_data)
    }
  }
}
