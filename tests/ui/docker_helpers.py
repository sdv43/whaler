"""Throwaway Docker containers and compose projects for the UI tests.

Everything is created with the LABEL label, so leftovers of an interrupted run can be removed.
"""

import json
import subprocess
import textwrap

LABEL = "com.github.sdv43.whaler.ui-test"
PREFIX = "wuit"
IMAGES = ("alpine:3", "nginx:alpine")

# prints a numbered line every second; RUN changes on every start of the container
LOGGER = 'RUN=$(head -c4 /dev/urandom | od -An -tx4 | tr -d " "); i=0; ' \
         'while true; do i=$((i+1)); echo "run $RUN line $i"; sleep 1; done'


def docker(*args, check=True):
    result = subprocess.run(["docker", *args], capture_output=True, text=True)
    if check and result.returncode != 0:
        raise RuntimeError(f"docker {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def pull_images():
    for image in IMAGES:
        if not docker("image", "ls", "-q", image):
            docker("pull", "-q", image)


def remove_leftovers():
    ids = docker("ps", "-aq", "--filter", f"label={LABEL}").split()

    # compose containers are recognized by the project name, which starts with the test prefix
    for line in docker("ps", "-a", "--format", '{{.ID}} {{.Label "com.docker.compose.project"}}').splitlines():
        container_id, _, project = line.partition(" ")
        if project.startswith(f"{PREFIX}-"):
            ids.append(container_id)

    if ids:
        docker("rm", "-f", *ids)

    networks = docker("network", "ls", "-q", "--filter", f"label={LABEL}").split()
    if networks:
        docker("network", "rm", *networks, check=False)


class Containers:
    """Containers of one test; all names start with the test's unique prefix."""

    def __init__(self, prefix, workdir):
        self.prefix = prefix
        self.workdir = workdir
        self.projects = []

    def name(self, suffix):
        return f"{self.prefix}-{suffix}"

    def run(self, suffix, *command, image="alpine:3", tty=False, ports=(), start=True):
        """Create a container; --init lets "docker stop" end shell loops without the 10s timeout."""
        name = self.name(suffix)
        args = ["run", "-d"] if start else ["create"]
        args += ["--init", "--name", name, "--label", LABEL]
        if tty:
            args.append("-t")
        for port in ports:
            args += ["-p", port]
        docker(*args, image, *command)
        return name

    def logger(self, suffix, tty=False):
        return self.run(suffix, "sh", "-c", LOGGER, tty=tty)

    def sleeper(self, suffix, start=True):
        return self.run(suffix, "sleep", "3600", start=start)

    def compose(self, suffix, services_yaml):
        """Start a compose project; services_yaml is the "services:" mapping."""
        project = self.name(suffix)
        path = self.workdir / f"{project}.yml"
        path.write_text(
            f"name: {project}\n"
            f"services:\n{textwrap.indent(textwrap.dedent(services_yaml).strip(), '  ')}\n"
            f"networks:\n  default:\n    labels: [{LABEL}]\n"
        )
        docker("compose", "-f", str(path), "up", "-d", "--quiet-pull")
        self.projects.append(path)
        return project

    def inspect(self, name):
        found = json.loads(docker("inspect", name, check=False) or "[]")
        return found[0] if found else None

    def state(self, name):
        info = self.inspect(name)
        return info["State"]["Status"] if info else None

    def started_at(self, name):
        return self.inspect(name)["State"]["StartedAt"]

    def project_states(self, project):
        output = docker("ps", "-a", "--filter", f"label=com.docker.compose.project={project}",
                        "--format", "{{.Label \"com.docker.compose.service\"}} {{.State}}")
        return dict(line.split() for line in output.splitlines())

    def host_port(self, name, container_port):
        """The published host address, e.g. '127.0.0.1:32768'."""
        return docker("port", name, container_port).splitlines()[0]

    def logs(self, name):
        return docker("logs", name).splitlines()

    def cleanup(self):
        for path in self.projects:
            docker("compose", "-f", str(path), "down", "-t", "1", check=False)

        ids = docker("ps", "-aq", "--filter", f"label={LABEL}", "--filter", f"name=^{self.prefix}-").split()
        if ids:
            docker("rm", "-f", *ids)
