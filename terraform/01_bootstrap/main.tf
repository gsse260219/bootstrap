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

resource "tfe_workspace" "workspaces" {
  for_each = { for ws in local.workspaces : "${ws.env}-${ws.subenv}-${ws["exec-mode"]}" => ws }

  name              = each.key
  working_directory = local.working_directories[each.value["exec-mode"]]

  vcs_repo {
    identifier                 = var.repo_identifier
    github_app_installation_id = var.github_app_installation_id
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
