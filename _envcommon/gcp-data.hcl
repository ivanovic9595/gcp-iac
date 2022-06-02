terraform {
  source = "github.com/ivanovic9595/terraform-modules.git//gcp-data?ref=0.3.1"
}

## Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/common/global/project-services",
  ]
}

## Variables:
inputs = {
}
