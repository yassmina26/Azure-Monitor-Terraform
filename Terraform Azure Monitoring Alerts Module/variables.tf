variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the scheduled query rule instance. Changing this forces a new resource to be created."
}

variable "location" {
  type        = string
  default     = ""
  description = "(Required) Specifies the Azure Region where the resource should exist. Changing this forces a new resource to be created."
}

variable "action_group_id" {
  type        = set(string)
  description = "(Optional) List of Action Group resource IDs to invoke when the alert fires."
}

variable "rule_scopes" {
  type        = list(string)
  description = " (Required) Specifies the list of resource IDs that this scheduled query rule is scoped to. Changing this forces a new resource to be created. Currently, the API supports exactly 1 resource ID in the scopes list."
}

###
###

variable "rules" {
  description = "(Required) Set of Scheduled query alert rules arguments."
  type = set(object({
    rule_name        = string               # (Required) Specifies the name which should be used for this Monitor Scheduled Query Rule. Changing this forces a new resource to be created
    rule_description = string               # (Optional) Specify what does the alert do
    enable_rule      = optional(bool, true) # (Optional) Whether this scheduled query rule is enabled. Default is true
    rule_severity    = number               # (Required) Severity of the alert. Should be an integer between 0 and 4. Value of 0 is severest.
    #rule_target_resource_types   = list(string) # (Optional) List of resource type of the target resource(s) on which the alert is created/updated. For example if the scope is a resource group and targetResourceTypes is Microsoft.Compute/virtualMachines, then a different alert will be fired for each virtual machine in the resource group which meet the alert criteria.
    rule_auto_mitigation_enabled = optional(bool, false) # (Optional) Specifies the flag that indicates whether the alert should be automatically resolved or not. Value should be true or false. The default is false.
    criteria = object({                                  # (Required) A criteria block as defined below.
      rule_evaluation_frequency    = string              # (Optional) How often the scheduled query rule is evaluated, represented in ISO 8601 duration format. Possible values are PT1M, PT5M, PT10M, PT15M, PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, PT6H, P1D.
      rule_window_duration         = string              # (Required) Specifies the period of time in ISO 8601 duration format on which the Scheduled Query Rule will be executed (bin size). If evaluation_frequency is PT1M, possible values are PT1M, PT5M, PT10M, PT15M, PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, and PT6H. Otherwise, possible values are PT5M, PT10M, PT15M, PT30M, PT45M, PT1H, PT2H, PT3H, PT4H, PT5H, PT6H, P1D, and P2D.
      rule_query                   = string              # (Required) The query to run on logs. The results returned by this query are used to populate the alert.
      rule_operator                = string              # (Required) Evaluation operation for rule - 'GreaterThan', GreaterThanOrEqual', 'LessThan', or 'LessThanOrEqual'.
      rule_threshold               = number              # (Required) Specifies the criteria threshold value that activates the alert.
      rule_time_aggregation_method = string              # (Required) The type of aggregation to apply to the data points in aggregation granularity. Possible values are Average, Count, Maximum, Minimum,and Total."
      rule_resource_id_column      = string              # (Optional) Specifies the column containing the resource ID. The content of the column must be an uri formatted as resource ID
      dimension = list(object({
        name     = string       # (Required) Name of the dimension.
        operator = string       # (Required) Operator for dimension values. Possible values are Exclude,and Include.
        values   = list(string) # (Required) List of dimension values. Use a wildcard * to collect all.
      }))
    })
  }))
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Tags for the alerts resource."
}
