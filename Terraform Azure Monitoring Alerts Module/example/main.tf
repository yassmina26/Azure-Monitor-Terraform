###
# Terraform implementation example
###
terraform {
  backend "azurerm" {} # Specifies Azure as the backend for storing Terraform state
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.78.0"
    }
  }
}

# Azure Provider Block
provider "azurerm" {
  subscription_id = var.SUBSCRIPTIONID # Replace with your Azure Subscription ID
  tenant_id       = var.tenant_id      # Replace with your Azure AD Tenant ID

  features {} # Enables provider features, such as Service Principal Mode
}

###
# Variables
###

variable "tenant_id" {
  type    = string
  default = ""
}

variable "SUBSCRIPTIONID" {
  type    = string
  default = ""
}
variable "ENVIRONMENT" {
  type = string
}

variable "APPLICATION" {
  type = string
}


###
## Data sources 
###


data "azurerm_log_analytics_workspace" "log" {
  name                = "testlogs" # Replace with the name of your Log Analytics workspace
  resource_group_name = "RG-LOG-NPD"
}

data "azurerm_monitor_action_group" "ag" {
  name                = "action-group-test" # Replace with the name of your action group
  resource_group_name = "RG-AG-TEST-WE"
}

##
### Resources 
##

module "azmonitor_query_based_alert" {
  source              = "git::source"
  resource_group_name = "RG-ALERTS-WE"             # Use the resource group name in which you want to create your alert
  rule_scopes         = [data.azurerm_log_analytics_workspace.log.id] # Use the ID of the resource you want to use as a scope of the alert rule
  action_group_id     = [data.azurerm_monitor_action_group.ag.id]     # Use the action group ID as an array because the parameter's type is a list.
  tags = {
    TERRAFORM = "true"
  }
  rules = [{
    rule_name        = "UnauthorizedAction_DomainMismatch_Alert"                                                                                  # Unique name for the alert rule
    rule_description = "This alert will raise if anyone with a domain name other than test.com has performed an action to any Azure resource." # Description providing details about the alert's purpose
    rule_severity    = 0                                                                                                                          # Severity level of the alert (0 = Critical, 1 = Error, 2 = Warning, 3 = Informational, 4 = Verbose)

    # Criteria for the alert rule
    criteria = {
      rule_evaluation_frequency = "PT1H" # Period of Time(1 hour in thise case)
      rule_window_duration      = "PT1H" # Period of Time(1 hour in thise case)

      # Kusto Query Language (KQL) query defining the conditions for the alert
      rule_query = <<-QUERY
            AzureActivity
            | where Caller has "@" and not(tostring(split(Caller, "@")[1]) contains "test.com")
            | project Caller, OperationNameValue, SubscriptionId, ResourceGroup, _ResourceId, ingestion_time()
        QUERY

      rule_operator                = "GreaterThan" # Operator used for comparison in the rule (e.g., GreaterThan)
      rule_threshold               = 0             # Threshold value for triggering the alert (0 in this case)
      rule_time_aggregation_method = "Count"       # Time aggregation method for the rule (Count in this case)
      rule_resource_id_column      = "_ResourceId" # Column in the query result used as the resource ID

      # This is a list of dimensions used for grouping and filtering the data in the alert rule.
      # The use of dimensions enhances the precision and customization of the alert rule criteria, 
      # allowing you to focus on specific attributes of the data and trigger alerts based on your defined conditions.
      dimension = [{
        name     = "Caller"
        operator = "Include"
        values   = ["*"] # Include all values for the "Caller" dimension
        },
        {
          name     = "SubscriptionId"
          operator = "Include"
          values   = ["*"] # Include all values for the "SubscriptionId" dimension
        },
        {
          name     = "OperationNameValue"
          operator = "Include"
          values   = ["*"] # Include all values for the "OperationNameValue" dimension
        }
      ]
    }
    },
    {
      rule_name        = "UnauthorizedBlobAccess_DomainMismatch_Alert"                                                            # Unique name for the alert rule
      rule_description = "This alert will raise if anyone with a domain name other than test.com has read access to the blob." # Description providing details about the alert's purpose
      rule_severity    = 0                                                                                                        # Severity level of the alert (0 = Critical, 1 = Error, 2 = Warning, 3 = Informational, 4 = Verbose)
      # Criteria for the alert rule
      criteria = {
        rule_evaluation_frequency = "PT1H" # Period of Time(1 hour in thise case)
        rule_window_duration      = "PT1H" # Period of Time(1 hour in thise case)

        # Kusto Query Language (KQL) query defining the conditions for the alert
        rule_query = <<-QUERY
              StorageBlobLogs
              | where RequesterUpn has "@" and not(tostring(split(RequesterUpn, "@")[1]) contains "test.com")
              | project RequesterUpn, Category, OperationName, _ResourceId, ingestion_time()

        QUERY

        rule_operator                = "GreaterThan" # Operator used for comparison in the rule (e.g., GreaterThan)
        rule_threshold               = 0             # Threshold value for triggering the alert (0 in this case)
        rule_time_aggregation_method = "Count"       # Time aggregation method for the rule (Count in this case)
        rule_resource_id_column      = "_ResourceId" # Column in the query result used as the resource ID

        # This is a list of dimensions used for grouping and filtering the data in the alert rule.
        # The use of dimensions enhances the precision and customization of the alert rule criteria, 
        # allowing you to focus on specific attributes of the data and trigger alerts based on your defined conditions.
        dimension = [{
          name     = "RequesterUpn"
          operator = "Include"
          values   = ["*"] # Include all values for the "Caller" dimension
          },
          {
            name     = "Category"
            operator = "Include"
            values   = ["*"] # Include all values for the "SubscriptionId" dimension
          },
          {
            name     = "OperationName"
            operator = "Include"
            values   = ["*"] # Include all values for the "OperationName" dimension
          }
        ]
      }
    }
  ]
}
###
# Outputting alert rule id
###

output "alert_rule_id" {
  value = module.azmonitor_query_based_alert.alert_rule_id
}
