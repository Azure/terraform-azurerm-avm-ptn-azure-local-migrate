# Output discovered servers
output "discovered_servers" {
  value = module.discover_vms.discovered_servers
}

output "discovered_servers_count" {
  value = module.discover_vms.discovered_servers_count
}
