################################################################################################
# This configuration requires a PagerDuty API Key added as a Terraform variable pd_token.
#
################################################################################################
variable "pd_token" {
  type = string
}
provider "pagerduty" {
#TEST DEMO - currently https://hug-terraform.pagerduty.com/

  token = var.pd_token
}

################################################################################################
# Create PagerDuty team
resource "pagerduty_team" "team_alpha" {
  name        = "Team Alpha"
  description = "Team Alpha"
}

#################################################################################################

#################################################################################################
# Create a PagerDuty users
resource "pagerduty_user" "responder1" {
  name  = "responder1"
  email = "responder1@pagerduty.demo"
  color = "dark-goldenrod"
  role = "admin"
}
resource "pagerduty_user" "responder2" {
  name  = "responder2"
  email = "responder2@pagerduty.demo"
  color = "chocolate"
  role = "user"
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
resource "pagerduty_team_membership" "responder1" {
  user_id = pagerduty_user.responder1.id
  team_id = pagerduty_team.team_alpha.id
}
resource "pagerduty_team_membership" "responder2" {
  user_id = pagerduty_user.responder1.id
  team_id = pagerduty_team.team_alpha.id
}
resource "pagerduty_team_membership" "responder3" {
  user_id = pagerduty_user.responder3.id
  team_id = pagerduty_team.team_alpha.id
}
resource "pagerduty_team_membership" "responder4" {
  user_id = pagerduty_user.responder4.id
  team_id = pagerduty_team.team_alpha.id
}
resource "pagerduty_team_membership" "responder5" {
  user_id = pagerduty_user.responder5.id
  team_id = pagerduty_team.team_alpha.id
}
resource "pagerduty_team_membership" "responder6" {
  user_id = pagerduty_user.responder6.id
  team_id = pagerduty_team.team_alpha.id
}
################################################################################################


# 7 Days 604800 1 Day 86400 14 Days 1209600 12 Hours 43200
################################################################################################
# Create PagerDuty Schedules
resource "pagerduty_schedule" "primary_sch" {
  name      = "Primary On-call Schedule"
  time_zone = "America/Chicago"
  layer {
    name                         = "Daily Rotation"
    start                        = "2020-09-01T20:00:00-10:00"
    rotation_virtual_start       = "2020-09-01T06:00:00+00:00"
    rotation_turn_length_seconds = 86400
    users                        = ["${pagerduty_user.responder1.id}",
                                    "${pagerduty_user.responder2.id}",
                                    "${pagerduty_user.responder3.id}",
                                    "${pagerduty_user.responder4.id}",
                                    "${pagerduty_user.responder5.id}",
                                    "${pagerduty_user.responder6.id}"]
  }
}
resource "pagerduty_schedule" "backup_sch" {
  name      = "Backup On-call Schedule"
  time_zone = "America/Chicago"
  layer {
    name                         = "Daily Rotation"
    start                        = "2020-09-01T20:00:00-10:00"
    rotation_virtual_start       = "2020-09-01T06:00:00+00:00"
    rotation_turn_length_seconds = 86400
    users                        = ["${pagerduty_user.responder2.id}",
                                    "${pagerduty_user.responder3.id}",
                                    "${pagerduty_user.responder4.id}",
                                    "${pagerduty_user.responder5.id}",
                                    "${pagerduty_user.responder6.id}",
                                    "${pagerduty_user.responder1.id}"]
  }
}
################################################################################################


################################################################################################
# Create PagerDuty EP's
resource "pagerduty_escalation_policy" "primary_ep" {
  name      = "Primary (EP)"
  num_loops = 2
  teams     = ["${pagerduty_team.team_alpha.id}"]

  rule {
    escalation_delay_in_minutes = 10

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.primary_sch.id
    }
  }
}

################################################################################################


################################################################################################
# Create PagerDuty Services
resource "pagerduty_service" "alpha_service" {
  name                    = "Alpha Service"
  auto_resolve_timeout    = 14400
  acknowledgement_timeout = 600
  escalation_policy       = pagerduty_escalation_policy.primary_ep.id
  alert_creation          = "create_alerts_and_incidents"
  alert_grouping          = "time"
  alert_grouping_timeout  = "10"

  incident_urgency_rule {
    type = "constant"
    urgency = "severity_based"
  }

}
