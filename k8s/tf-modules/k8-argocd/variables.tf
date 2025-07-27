variable "argocd_namespace" {
  type        = string
  default     = "argocd"
}

# Git repo that contains your Argo CD app-of-apps definitions
variable "bootstrap_repo_url" {
  type        = string
  description = "Git repo URL that has the root Application (or a directory of apps)."
  default     = "https://github.com/your-org/your-gitops-repo.git"
}

variable "bootstrap_repo_revision" {
  type        = string
  description = "Git revision (branch/tag/commit) for the bootstrap repo."
  default     = "main"
}

variable "bootstrap_repo_path" {
  type        = string
  description = "Path inside the repo that defines the children apps (e.g. 'apps')."
  default     = "clusters/prod"
}