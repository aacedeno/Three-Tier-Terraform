#------ loadbalancing/outputs.tf --------

output "ext_alb_tg" {
  value = aws_lb_target_group.web_servers_tg
}