from __future__ import annotations

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def test_slim_image_declares_hermes_runtime_user() -> None:
    dockerfile = (REPO_ROOT / "Dockerfile.slim").read_text(encoding="utf-8")

    assert "useradd -u 10000" in dockerfile
    assert "-d /opt/data/home" in dockerfile
    assert "hermes" in dockerfile


def test_slim_entrypoint_drops_root_before_exec() -> None:
    entrypoint = (REPO_ROOT / "docker" / "entrypoint-slim.sh").read_text(
        encoding="utf-8"
    )

    assert "exec_as_runtime_user" in entrypoint
    assert 'pwd.getpwnam("hermes")' in entrypoint
    assert "os.setgid(target.pw_gid)" in entrypoint
    assert "os.initgroups(target.pw_name, target.pw_gid)" in entrypoint
    assert "os.setuid(target.pw_uid)" in entrypoint
    assert 'chown -R hermes:hermes "$HERMES_HOME"' in entrypoint
    assert 'exec_as_runtime_user "$@"' in entrypoint
    assert 'exec_as_runtime_user hermes "$@"' in entrypoint
