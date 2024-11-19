terraform {
  backend "remote" {
    organization = "hexlet-project"
    workspaces {
      name = "hexlet-project"
    }
  }
}
