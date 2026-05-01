output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cpu_alarm_name" {
  description = "Name of the CPU high alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "memory_alarm_name" {
  description = "Name of the memory high alarm"
  value       = aws_cloudwatch_metric_alarm.memory_high.alarm_name
}
