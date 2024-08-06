output "alb_url" {
  value = "https://${module.ecs.alb_dns_name}/"
}
