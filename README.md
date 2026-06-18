# DevOps Labs

## Lab 1

I wanted to go off-script a little, and test if NixOS is any good for this kind
of application. Now I'm also far behind the schedule.

My findings are:

- Their DSL is confusing, and when working with Nix, I have to do *everything*
  in Nix (the language). When somebody else goes through the trouble to make
  something configurable through Nix, though, it becomes rather convenient, see
  [./nixos/common.nix](nixos/common.nix).
  But still no way I'm migrating to home-manager for personal use any time soon.

- If the host machine also uses Nix, it can autogenerate and run a qemu VM with
  the declared settings. Except all the dependencies are built on the host, so I
  had to cross extra layers of hell to run aarch64-linux builder (wasn't too
  hard).

- It's easy to set up development environments with Nix:
  [./flake.nix](flake.nix): I can install packages only accessible in a separate
  dev shell, I can use `direnv` to automatically activate it when I'm `cd`-ing
  into the project folder, and I can specify environment variables and shell
  hooks.

  I also made the subshell switch to its own separate command history
  after cluttering my fuzzy history search to the point when it didn't even match
  anything useful.

> [!NOTE]
> For the record, I don't hide LLM usage in the repo: the web app was basically
> vibe-coded as I think writing a CRUD is outside the scope of the lab. I can
> promise I'm not getting the hours spent on manually trying to get the VM to
> work, though.

Anyway,

### Task

Student number: 25

App port: 8080

App type: Task Tracker

Database: PostgreSQL

Config path: `/etc/webapp/config.toml`

### Dev env and running the server

#### aarch64-darwin + Nix (my system)

The guest is `aarch64-linux`, in order to build Linux packages on the host, enable linux-builder:

```nix
nix.linux-builder.enable = true;
# pin to stable nixpkgs 26.05 (qemu 10.x.x).
# the 11.0.0 update suddenly breaks everything.
nix.linux-builder.config =
{ lib, ... }:
{
  virtualisation.qemu.package = lib.mkForce nixpkgs-stable.legacyPackages."aarch64-darwin".qemu;
};
nix.settings.builders = "@/etc/nix/machines";
```

Enter the dev shell (installs `qemu`, `just`, `expect`):

```bash
nix develop
```

Run the service with:

```bash
just vm
# which is actually:
nix run .#vm
```

Log in as `student`/`teacher`/`operator` (12345678) and check the service health:

```bash
systemctl status mywebapp
```

#### Any aarch64 or x86_64 host

Install: `qemu`, `just`, `expect`.

Download the minimal NixOS 26.05 .iso [here](https://nixos.org/download/)
(direct URLs:
[aarch64](https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-aarch64-linux.iso)
[x86_64](https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso)).

Set up and run the VM:

```bash
./deploy/setup.sh path/to/nixos-minimal-26.05.12345-6789.iso
./deploy/run.sh
```

### Verifying results

```bash
# is app accessible
curl localhost:8080/health/alive
# is DB connected
curl localhost:8080/health/ready

# DB writes work
curl --json '{"title": "Sweep the house"}' localhost:8080/tasks
curl -H "Accept: application/json" localhost:8080/tasks
```
