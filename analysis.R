require(ggplot2)
require(reshape2)
require(dplyr)

cilow <- function (data) {
  ci <- t.test(data)
  return(ci$conf.int[1])
}

cihigh <- function (data) {
  ci <- t.test(data)
  return(ci$conf.int[2])
}

total_time <- read.csv("total_time.csv")
cpu_usage <- read.csv("cpu_usage.csv")

# The values in cpu_usage.csv overestimate the usage of cpu. Here the values are corrected.
correction_factor <- total_time$scaling_period - total_time$total_time%%total_time$scaling_period
cpu_usage$cpu_usage <- cpu_usage$cpu_usage - correction_factor

# ----------------------------------------------------------------------------------------------------------------

mean_times <- total_time %>% group_by(scaling_period, cap_change, start_cap) %>% summarise(mean = mean(total_time))
mean_cpu_usage <- cpu_usage %>% group_by(scaling_period, cap_change, start_cap) %>% summarise(mean_cpu = mean(cpu_usage))
mean_cap_changes <- cpu_usage %>% group_by(scaling_period, cap_change, start_cap) %>% summarise(mean_changes = mean(cap_changes))

mean_times_cpu <- data.frame(scaling_period = mean_times$scaling_period, 
                        cap_change = mean_times$cap_change, 
                        start_cap = mean_times$start_cap, 
                        mean_time = mean_times$mean, 
                        mean_cpu = mean_cpu_usage$mean_cpu,
                        mean_cap_changes = mean_cap_changes$mean_changes)

ggplot(mean_times_cpu, aes(mean_time, mean_cpu, label = scaling_period)) + geom_point() + geom_text(hjust = 0, nudge_x = 1)
ggplot(mean_times_cpu, aes(mean_time, mean_cpu, label = cap_change)) + geom_point() + geom_text(hjust = 0, nudge_x = 1)
ggplot(mean_times_cpu, aes(mean_time, mean_cpu, label = start_cap)) + geom_point() + geom_text(hjust = 0, nudge_x = 1)

write.csv(mean_times_cpu, file = "times_cpu.csv")

# ----------------------------------------------------------------------------------------------------------------
# Plots
# ----------------------------------------------------------------------------------------------------------------

plot_scaling_period <- function(total_time, cpu_usage) {
  times_cpu <- data.frame(scaling_period = total_time$scaling_period,
                          cap_change = total_time$cap_change,
                          start_cap = total_time$start_cap,
                          total_time = total_time$total_time,
                          cpu_usage = cpu_usage$cpu_usage,
                          cap_changes = cpu_usage$cap_changes)
  
  # Make a column from the dependent variables columns
  scaling_time_data <- melt(times_cpu, id=c("scaling_period","cap_change","start_cap"), variable.name = "dependent_variable")
  # Calculate confidence intervals
  scaling_time_data <- scaling_time_data %>% group_by(dependent_variable, scaling_period, cap_change, start_cap) %>% summarise(low = cilow(value), high=mean(value))
  # Separate most important factor, create columns from combinations of remaining factors
  scaling_time_data <- dcast(scaling_time_data, scaling_period + dependent_variable + low + high ~ cap_change + start_cap, length)
  # Make remaining factors combinations a single column
  scaling_time_data <- melt(scaling_time_data, id=c("scaling_period", "dependent_variable", "low", "high"), variable.name = "cap_change_start_cap", value.name = "value2")
  # Remove repeated values
  scaling_time_data <- filter(scaling_time_data, value2 != 0)
  scaling_time_data <- arrange(scaling_time_data, dependent_variable, scaling_period, cap_change_start_cap)
  
  limits <- aes(ymax = scaling_time_data$high, ymin = scaling_time_data$low)
  ggplot(scaling_time_data, aes(x=cap_change_start_cap,y=(high+low)/2)) + 
    geom_point() +
    facet_grid(dependent_variable ~ scaling_period, scales="free") +
    geom_errorbar(limits) +
    xlab("CAP change - start CAP") +
    ylab("")
  
  ggsave("experiment_parameter_control_scaling_period.png")
}

plot_start_cap <- function(total_time, cpu_usage) {
  times_cpu <- data.frame(scaling_period = total_time$scaling_period,
                          cap_change = total_time$cap_change,
                          start_cap = total_time$start_cap,
                          total_time = total_time$total_time,
                          cpu_usage = cpu_usage$cpu_usage,
                          cap_changes = cpu_usage$cap_changes)
  
  # Make a column from the dependent variables columns
  start_cap_data <- melt(times_cpu, id=c("scaling_period","cap_change","start_cap"), variable.name = "dependent_variable")
  # Calculate confidence intervals
  start_cap_data <- start_cap_data %>% group_by(dependent_variable, scaling_period, cap_change, start_cap) %>% summarise(low = cilow(value), high=mean(value))
  # Separate most important factor, create columns from combinations of remaining factors
  start_cap_data <- dcast(start_cap_data, start_cap + dependent_variable + low + high ~ scaling_period + cap_change, length)
  # Make remaining factors combinations a single column
  start_cap_data <- melt(start_cap_data, id=c("start_cap", "dependent_variable", "low", "high"), variable.name = "cap_change_scaling_period", value.name = "value2")
  # Remove repeated values
  start_cap_data <- filter(start_cap_data, value2 != 0)
  start_cap_data <- arrange(start_cap_data, dependent_variable, start_cap, cap_change_scaling_period)
  
  limits <- aes(ymax = start_cap_data$high, ymin = start_cap_data$low)
  ggplot(start_cap_data, aes(x=cap_change_scaling_period,y=(high+low)/2)) + 
    geom_point() + 
    facet_grid(dependent_variable ~ start_cap, scales="free") + 
    geom_errorbar(limits) +
    xlab("scaling period - CAP change") +
    ylab("")
  
  ggsave("experiment_parameter_control_start_cap.png")
}

plot_scaling_period(total_time, cpu_usage)
plot_start_cap(total_time, cpu_usage)
