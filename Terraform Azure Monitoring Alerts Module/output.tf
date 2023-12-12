output "alert_rule_id" {
  value = {
    for key, alert_rule in azurerm_monitor_scheduled_query_rules_alert_v2.query_rules_alert :
    key => alert_rule.id
  }
  description = "Retrieve the alert rules IDs."
}
 
