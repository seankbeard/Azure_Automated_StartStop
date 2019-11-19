# Configure the Microsoft Azure Provider
provider "azurerm" {
}

# Resource Group
variable "ResGroup" {
    type = "string"
    default = "ddbanz-automation-scripts"
}

# Azure Location
variable "Location" {
    type = "string"
    default = "australiasoutheast"
}

# Resource Tag
variable "Description" {
    type = "string"
    default = "DDBANZ_Automation"
}


# Resource Tag
variable "Environment" {
    type = "string"
    default = "test"
}

# Automation Account Name
variable "AutomationAccount" {
    type = "string"
    default = "ddbanz-automationaccount"
}

# Service Principle
variable "AppName" {
    type = "string"
    default = "AutomationAccount"
}

# Service Principle
variable "CertPassword" {
    type = "string"
    default = "C0mplexPassw0rd!"
}

# Service Principle
variable "SubscriptionId" {
    type = "string"
    default = "2a688836-5806-4ae5-a0f2-ac6b594d1bfb"
}

# For Start/Stop Target
variable "TagName" {
    type = "string"
    default = "AutoShutdown"
}

# For Start/Stop Target
variable "TagKey" {
    type = "string"
    default = "yes"
}

# For Start/Stop Schedule
variable "StartTime" {
    ##default = "2018-11-28T17:00:00+00:00"
    default = "06:00"
}

# For Start/Stop Schedule
variable "StopTime" {
    ##default = "2018-11-29T06:00:00+00:00"
    default = "19:00"
}