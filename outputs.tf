output "dashboard_url" {
  value = module.container_apps.container_app_fqdn["dashboard"]
}
output "http_echo_url" {
  value = module.container_apps.container_app_fqdn["http_echo"]
}