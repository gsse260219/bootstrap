locals {
  working_directories = {
    remote : "./terraform/02_remote",
    agent : "./terraform/03_agent",
  }
  workspaces = [
    { env = "npi", subenv = "main", exec-mode = "remote" },
    { env = "npi", subenv = "main", exec-mode = "agent" },
    { env = "npi", subenv = "sandbox", exec-mode = "remote" },
    { env = "npi", subenv = "sandbox", exec-mode = "agent" },
  ]
}

data "tfe_project" "project" {
  organization = var.organization
  name         = var.project_name
}

resource "tfe_workspace" "workspaces" {
  for_each = { for ws in local.workspaces : "${ws.env}-${ws.subenv}-${ws["exec-mode"]}" => ws }

  name              = each.key
  organization      = var.organization
  working_directory = local.working_directories[each.value["exec-mode"]]
  project_id        = data.tfe_project.project.id

  vcs_repo {
    identifier     = var.repo_identifier
    oauth_token_id = var.oauth_token_id
  }
}

resource "tfe_variable" "plan_args" {
  for_each     = { for ws in local.workspaces : "${ws.env}-${ws.subenv}-${ws["exec-mode"]}" => ws }
  workspace_id = tfe_workspace.workspaces[each.key].id
  key          = "TF_CLI_ARGS_plan"
  value        = "--var-file=\"./tfvars/${each.value.env}-${each.value.subenv}.tfvars\""
  category     = "env"
  sensitive    = false
}

resource "tfe_variable" "apply_args" {
  for_each     = { for ws in local.workspaces : "${ws.env}-${ws.subenv}-${ws["exec-mode"]}" => ws }
  workspace_id = tfe_workspace.workspaces[each.key].id
  key          = "TF_CLI_ARGS_apply"
  value        = "--var-file=\"./tfvars/${each.value.env}-${each.value.subenv}.tfvars\""
  category     = "env"
  sensitive    = false
}
