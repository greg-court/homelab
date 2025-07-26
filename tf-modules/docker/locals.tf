locals {
  gh_shared_env = alltrue([var.gh_homelab_admin_pat != null, var.gh_homelab_repo_url != null]) ? [
    "GH_PAT=${var.gh_homelab_admin_pat}",
    "REPO_URL=${var.gh_homelab_repo_url}"
  ] : []

  container_definitions = {
    gh_ansible_runners = {
      image              = "gr10/gh-ansible-runner:latest"
      env                = concat(local.gh_shared_env, ["RUNNER_LABELS=self-hosted,ansible"])
      network_mode       = "host"
      agent_name_env_var = "RUNNER_NAME"

      instances = try(var.container_instances.gh_ansible_runners, {})
    }

    gh_docker_runners = {
      image = "gr10/gh-docker-runner:latest"
      env   = concat(local.gh_shared_env, ["RUNNER_LABELS=self-hosted,docker"])
      volumes = [{
        host_path      = "/var/run/docker.sock"
        container_path = "/var/run/docker.sock"
      }]
      group_add          = ["990"]
      agent_name_env_var = "RUNNER_NAME"

      instances = try(var.container_instances.gh_docker_runners, {})
    }

    gh_packer_runners = {
      image = "gr10/gh-packer-runner:latest"
      env   = concat(local.gh_shared_env, ["RUNNER_LABELS=self-hosted,packer", "RUNNER_HOSTNAME=${var.docker_host}"])
      volumes = [{
        host_path      = "/mnt/iso_storage"
        container_path = "/mnt/iso_storage"
      }]
      ports              = [{ internal = 8080 }]
      agent_name_env_var = "RUNNER_NAME"

      instances = try(var.container_instances.gh_packer_runners, {})
    }

    gh_terraform_runners = {
      image = "gr10/gh-terraform-runner:latest"
      env = concat(local.gh_shared_env, [
        "RUNNER_LABELS=self-hosted,terraform",
      ])
      agent_name_env_var = "RUNNER_NAME"

      instances = try(var.container_instances.gh_terraform_runners, {})
    }

    tfc_agents = {
      image              = "hashicorp/tfc-agent:latest"
      env                = var.tfc_agent_token != null ? ["TFC_AGENT_TOKEN=${var.tfc_agent_token}"] : []
      agent_name_env_var = "TFC_AGENT_NAME"

      instances = try(var.container_instances.tfc_agents, {})
    }

    n8n = {
      image = "n8nio/n8n:latest"
      env = [
        "N8N_PROTOCOL=http",
        "N8N_PORT=5678",
        "N8N_SECURE_COOKIE=false",
      ]
      ports     = [] # No default ports; override in tfvars if direct access needed
      instances = try(var.container_instances.n8n, {})
    }

    traefik = {
      image = "traefik:latest"
      volumes = [
        { host_path = "/var/run/docker.sock", container_path = "/var/run/docker.sock", read_only = true }
      ]
      env = [
        "TRAEFIK_LOG_LEVEL=INFO",
        "TRAEFIK_PROVIDERS_DOCKER=true",
        "TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT=false",
        "TRAEFIK_ENTRYPOINTS_WEB_ADDRESS=:80",
        "TRAEFIK_ENTRYPOINTS_WEB_HTTP_REDIRECTIONS_ENTRYPOINT_TO=websecure",
        "TRAEFIK_ENTRYPOINTS_WEB_HTTP_REDIRECTIONS_ENTRYPOINT_SCHEME=https",
        "TRAEFIK_ENTRYPOINTS_WEBSECURE_ADDRESS=:443",
        "TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS=true",
        "TRAEFIK_ENTRYPOINTS_TRAEFIK_ADDRESS=:8080",
        "TRAEFIK_API_DASHBOARD=true",
        "TRAEFIK_API=true"
      ]
      instances = try(var.container_instances.traefik, {})
    }
    nginx = {
      image        = "nginx:latest"
      ports        = [] # No direct ports exposed—let Traefik handle routing via labels
      command      = ["nginx", "-g", "daemon off;"]
      env          = []
      volumes      = []
      capabilities = null
      mounts       = []
      instances    = try(var.container_instances.nginx, {})
    }
    hashicorp_vault = {
      image = "hashicorp/vault:latest"
      env   = []
      capabilities = {
        add = ["CAP_IPC_LOCK"]
      }
      instances = try(var.container_instances.hashicorp_vault, {})
    }
  }

  active_container_types = [for k in keys(local.container_definitions) : k if length(local.container_definitions[k].instances) > 0]

  all_instances = merge(flatten([
    for type_key, def in local.container_definitions : [
      for inst_name, inst_def in def.instances : {
        "${type_key}.${inst_name}" = merge(
          def,
          { # Override with instance-specific settings
            container_type = type_key
            instance_name  = inst_name
            instance_cfg   = inst_def
            group_add      = concat(try(def.group_add, []), try(inst_def.group_add, []))
            network_mode   = try(inst_def.network_mode, def.network_mode, null)
            env_final      = concat(try(def.env, []), try(def.agent_name_env_var, null) != null ? ["${def.agent_name_env_var}=${inst_name}"] : [], try(inst_def.env, []))
            volumes        = concat(try(def.volumes, []), try(inst_def.volumes, []))
            mounts         = concat(try(def.mounts, []), try(inst_def.mounts, []))
            ports          = concat(try(def.ports, []), try(inst_def.ports, []))
            command        = concat(try(def.command, []), try(inst_def.command, []))
            labels         = merge(try(def.labels, {}), try(inst_def.labels, {}))
            capabilities   = try(inst_def.capabilities, def.capabilities, null)
          }
        )
      }
    ]
  ])...)
}