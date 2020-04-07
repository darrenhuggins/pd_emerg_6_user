################################################################################################
# This configuration requires a PagerDuty API Key and the Destination instance to have Prioties
# enabled to support event rule creation. Use the API key to generate the Priotiy ID's here:
# https://api-reference.pagerduty.com/#!/Priorities/get_priorities
# To Destroy the config run Destroy twice (perhaps a bug in the provider)
################################################################################################
variable "pd_token" {
  type = string
}
provider "pagerduty" {
#TEST DEMO - currently https://hug-terraform.pagerduty.com/
#  token = "6yV68ZEheDWZRwWSpW8F"
  token = var.pd_token
}

################################################################################################
# Create PagerDuty teams - Automation, Operations, Banking Development (DevOps), Management
resource "pagerduty_team" "Operations" {
  name        = "Emergency Response Team"
  description = "Emergency Team"
}
resource "pagerduty_team" "Stakeholders" {
  name        = "Stakeholders"
  description = "Management Team"
}

################################################################################################



################################################################################################
# Create a PagerDuty users

resource "pagerduty_user" "responder1" {
  name  = "responder1"
  email = "responder1@pagerduty.demo"
  color = "dark-goldenrod"
  role = "admin"
}
resource "pagerduty_user" "responder2" {
  name  = "responder2"
  email = "responder3@pagerduty.demo"
  color = "chocolate"
  role = "limited_user"
}
resource "pagerduty_user" "responder3" {
  name  = "responder3"
  email = "responder3@pagerduty.demo"
  role = "user"
}
resource "pagerduty_user" "responder4" {
  name  = "responder4"
  email = "responder4@pagerduty.demo"
  role = "user"
}
resource "pagerduty_user" "responder5" {
  name  = "responder5"
  email = "responder5@pagerduty.demo"
}
resource "pagerduty_user" "responder6" {
  name  = "responder6"
  email = "responder6@pagerduty.demo"
}
################################################################################################


################################################################################################
# Assign the Users to the right Teams: -
resource "pagerduty_team_membership" "teamOps" {
  user_id = pagerduty_user.responder1.id
  team_id = pagerduty_team.Operations.id
}

################################################################################################


# 7 Days 604800 1 Day 86400 14 Days 1209600 12 Hours 43200
################################################################################################
# Create PagerDuty Schedules
resource "pagerduty_schedule" "operations_sch" {
  name      = "Emergency On-call Schedule"
  time_zone = "America/Chicago"
  layer {
    name                         = "Weekly Rotation"
    start                        = "2018-11-06T20:00:00-10:00"
    rotation_virtual_start       = "2018-11-07T06:00:00+00:00"
    rotation_turn_length_seconds = 86400
    users                        = ["${pagerduty_user.responder1.id}",
                                    "${pagerduty_user.responder2.id}",
                                    "${pagerduty_user.responder3.id}",
                                    "${pagerduty_user.responder4.id}",
                                    "${pagerduty_user.responder5.id}",
                                    "${pagerduty_user.responder6.id}"]
	restriction {
      type              = "daily_restriction"
      start_time_of_day = "08:00:00"
      duration_seconds  = 86400
	}
  }
}
################################################################################################



################################################################################################
# Create PagerDuty EP's
resource "pagerduty_escalation_policy" "OperationsEP" {
  name      = "WU eCommerce Engineering (EP)"
  num_loops = 2
  teams     = ["${pagerduty_team.Operations.id}"]

  rule {
    escalation_delay_in_minutes = 10

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.operations_sch.id
    }
  }
}

################################################################################################



################################################################################################
# Create PagerDuty Services
resource "pagerduty_service" "EmergencyResponse" {
  name                    = "Emergency Response Team"
  auto_resolve_timeout    = 14400
  acknowledgement_timeout = 600
  escalation_policy       = pagerduty_escalation_policy.OperationsEP.id
  alert_creation          = "create_alerts_and_incidents"
  alert_grouping          = "time"
  alert_grouping_timeout  = "10"

  incident_urgency_rule {
    type = "constant"
    urgency = "severity_based"
  }

}
