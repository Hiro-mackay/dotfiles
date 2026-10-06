# What Claude Code and Codex must not do, in one list for both: commands they must not
# run, and files (relative to home) they must not read. programs/claude turns it into
# permissions.deny; programs/codex into execpolicy rules and a permission profile.
{
  commands = [
    [ "sudo" ]
    [
      "git"
      "reset"
      "--hard"
    ]
    [
      "git"
      "push"
      "--force"
    ]
    [
      "git"
      "push"
      "-f"
    ]
    [
      "git"
      "clean"
    ]
    [
      "rm"
      "-rf"
    ]
  ];
  secrets = [
    ".ssh"
    ".aws"
    ".gnupg"
    ".kube"
    ".netrc"
    ".npmrc"
    ".docker/config.json"
    ".config/gh/hosts.yml"
    ".config/gcloud"
    ".config/sops"
    ".codex/auth.json"
    ".claude/.credentials.json"
  ];
}
