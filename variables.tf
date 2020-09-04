locals {
  start_time_srv_app_gw = "${formatdate("YYYY-MM-DD", timeadd(timestamp(), "18h"))}T05:00:00-06:00"
  stop_time_srv_app_gw  = "${formatdate("YYYY-MM-DD", timeadd(timestamp(), "18h"))}T05:30:00-06:00"
}

variable environment {
  type        = string
  description = "Current Environment"
  default     = "dev"
}

variable main_rg_name {
  type        = string
  description = "Instances name"
  default     = "NekoResourceGroup"
}

variable rg_agent_pool {
  type        = string
  description = "Resource Agent Pool"
  default     = "MC_NekoResourceGroup_NekoAKS_eastus"
}

variable aks_agent_pool {
  type        = string
  description = "AKS Agent Pool"
  default     = "aks-agentpool-23362959-vmss"
}
