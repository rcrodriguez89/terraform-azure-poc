provider azurerm {
  features {}
}

data azurerm_resource_group rg {
  name = var.main_rg_name
}

resource azurerm_automation_account ac {
  count               = var.environment == "dev" ? 1 : 0
  name                = "AutomationAccountTF"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku_name            = "Basic"

  tags = {
    environment = "development-tf"
  }
}

resource azurerm_automation_module mod_az_accounts {
  count                   = var.environment == "dev" ? 1 : 0
  name                    = "Az.Accounts"
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.ac[count.index].name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.accounts.1.9.2.nupkg"
  }
}

resource azurerm_automation_module mod_az_network {
  count                   = var.environment == "dev" ? 1 : 0
  name                    = "Az.Network"
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.ac[count.index].name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/az.network.3.3.0.nupkg"
  }

  depends_on = [
    azurerm_automation_module.mod_az_accounts,
  ]
}

data local_file script_pws_start_srv_app_gw {
  filename = "${path.module}/powershell-scripts/StartServiceApplicationGateway.ps1"
}

data local_file script_pws_stop_srv_app_gw {
  filename = "${path.module}/powershell-scripts/StopServiceApplicationGateway.ps1"
}

resource azurerm_automation_runbook rb_start_srv_app_gw {
  count                   = var.environment == "dev" ? 1 : 0
  name                    = "StartServiceAppGatewayRunbook"
  location                = data.azurerm_resource_group.rg.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.ac[count.index].name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Init Application Gateway Service"
  runbook_type            = "PowerShell"
  content                 = data.local_file.script_pws_start_srv_app_gw.content

  depends_on = [
    azurerm_automation_account.ac
  ]
}

resource azurerm_automation_runbook rb_stop_srv_app_gw {
  count                   = var.environment == "dev" ? 1 : 0
  name                    = "StopServiceAppGatewayRunbook"
  location                = data.azurerm_resource_group.rg.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.ac[count.index].name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Stop Application Gateway Service"
  runbook_type            = "PowerShell"
  content                 = data.local_file.script_pws_stop_srv_app_gw.content

  depends_on = [
    azurerm_automation_account.ac
  ]
}

resource azurerm_automation_schedule sch_start_srv_app_gw {
  count                   = var.environment == "dev" ? 1 : 0
  name                    = "StartServiceAppGatewaySchedule"
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.ac[count.index].name
  frequency               = "Week"
  interval                = 1
  //timezone                = "Central America Standard Time"
  timezone    = "America/Costa_Rica"
  start_time  = "${local.start_time_srv_app_gw}"
  description = "Will Start Application Gateway Service"
  week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
}

resource azurerm_automation_schedule sch_stop_srv_app_gw {
  count                   = var.environment == "dev" ? 1 : 0
  name                    = "StopServiceAppGatewaySchedule"
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.ac[count.index].name
  frequency               = "Week"
  interval                = 1
  //timezone                = "Central America Standard Time"
  timezone    = "America/Costa_Rica"
  start_time  = "${local.stop_time_srv_app_gw}"
  description = "Will Stop Application Gateway Service"
  week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
}

resource azurerm_automation_job_schedule job_start_srv_app_gw {
  count                   = var.environment == "dev" ? 1 : 0
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.ac[count.index].name
  runbook_name            = azurerm_automation_runbook.rb_start_srv_app_gw[count.index].name
  schedule_name           = azurerm_automation_schedule.sch_start_srv_app_gw[count.index].name
}

resource azurerm_automation_job_schedule job_stop_srv_app_gw {
  count                   = var.environment == "dev" ? 1 : 0
  resource_group_name     = data.azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.ac[count.index].name
  runbook_name            = azurerm_automation_runbook.rb_stop_srv_app_gw[count.index].name
  schedule_name           = azurerm_automation_schedule.sch_stop_srv_app_gw[count.index].name
}


# AKS Cluster

data azurerm_resource_group rg_ap {
  name = var.rg_agent_pool
}

data azurerm_virtual_machine_scale_set vm_scale_set {
  name                = var.aks_agent_pool
  resource_group_name = data.azurerm_resource_group.rg_ap.name
}


resource "azurerm_monitor_autoscale_setting" "auto_sc_setting" {
  name                = "aks-agentpool-23362959-vmss-Autoscale-945"
  enabled             = true
  resource_group_name = data.azurerm_resource_group.rg_ap.name
  location            = data.azurerm_resource_group.rg_ap.location
  target_resource_id  = data.azurerm_virtual_machine_scale_set.vm_scale_set.id

  profile {
    name = "Working-Hours"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_resource_id = data.azurerm_virtual_machine_scale_set.vm_scale_set.id
        metric_name        = "Percentage CPU"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    recurrence {
      timezone = "Central America Standard Time"
      days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      hours    = [8]
      minutes  = [0]
    }
  }

  profile {
    name = "Resting-Hours"

    capacity {
      default = 0
      minimum = 0
      maximum = 0
    }

    recurrence {
      timezone = "Central America Standard Time"
      days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      hours    = [16]
      minutes  = [0]
    }
  }
}
