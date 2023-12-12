###
# Terraform Configuration for Azure Monitor Query Alert Rules
###

# Specify the required providers and versions
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.78.0"
    }
  }
  required_version = ">= 1.5"
}

###
# Data sources
###

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

###
# Resources
###

# Create Azure Monitor Scheduled Query Alert rules based on user-defined rules
#It uses the for_each expression to iterate over the rules set.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "query_rules_alert" {
  for_each                = { for val in var.rules : val.rule_name => val }
  name                    = each.value.rule_name
  description             = each.value.rule_description
  resource_group_name     = var.resource_group_name
  location                = coalesce(var.location, data.azurerm_resource_group.rg.location)
  enabled                 = each.value.enable_rule #Define whether this alert rule will be enabled or disabled
  auto_mitigation_enabled = each.value.rule_auto_mitigation_enabled

  # Specify the data source, severity, query, frequency, and time window for the alert rule
  scopes   = var.rule_scopes          # Specify the scope to apply the Query Alert rule
  severity = each.value.rule_severity # Specify the severity level of the alert rule

  criteria {
    query = each.value.criteria.rule_query # Specify the Kusto Query Language (KQL) query for the alert rule
    # the following arguments specify the conditions that trigger the alert rule, such as the operator and threshold.
    operator                = each.value.criteria.rule_operator
    threshold               = each.value.criteria.rule_threshold
    time_aggregation_method = each.value.criteria.rule_time_aggregation_method
    resource_id_column      = each.value.criteria.rule_resource_id_column
    dynamic "dimension" {
      for_each = each.value.criteria.dimension

      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }
  }
  evaluation_frequency = each.value.criteria.rule_evaluation_frequency # Specify how often the alert rule should run, should be less than or equal to the window duration 
  window_duration      = each.value.criteria.rule_window_duration      # Specify the time window during which the query should be evaluated for triggering the alert

  # Configure the action to be taken when the alert is triggered, such as notifying an action group or sending an email.
  action {
    action_groups = var.action_group_id
  }
  tags = var.tags
}
