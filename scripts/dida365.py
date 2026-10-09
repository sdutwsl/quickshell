#!/usr/bin/env python3
"""Dida365 private-API bridge used by QuickShell.

Credentials:
  ~/.config/quickshell/dida365.json

Cached reusable session:
  ~/.cache/quickshell/dida365-session.json

Only Python's standard library is required.
"""

from __future__ import annotations

import hashlib
import json
import os
import secrets
import socket
import sys
import time
from http.cookies import SimpleCookie
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

API_BASE = "https://api.dida365.com/api/v2"
LOGIN_URL = API_BASE + "/user/signon?wc=true&remember=true"

CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
CONFIG_DIR = CONFIG_HOME / "quickshell"
CACHE_DIR = CACHE_HOME / "quickshell"
CONFIG_PATH = CONFIG_DIR / "dida365.json"
SESSION_PATH = CACHE_DIR / "dida365-session.json"
AUTH_STATE_PATH = CACHE_DIR / "dida365-auth-state.json"


class ApiError(Exception):
    def __init__(self, status: int, body: str, retry_after: str | None = None):
        self.status = status
        self.body = body
        self.retry_after = retry_after
        super().__init__(f"HTTP {status}: {body}")


def emit(payload: dict[str, Any], exit_code: int = 0) -> None:
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(exit_code)


def fail(code: str, message: str, *, configured: bool = True, details: str = "") -> None:
    emit(
        {
            "ok": False,
            "error": code,
            "message": message,
            "details": details,
            "configured": configured,
            "configPath": str(CONFIG_PATH),
        },
        1,
    )


def atomic_json_write(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        path.parent.chmod(0o700)
    except OSError:
        pass

    tmp = path.with_name(path.name + ".tmp-" + secrets.token_hex(4))
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    try:
        tmp.chmod(0o600)
    except OSError:
        pass
    tmp.replace(path)
    try:
        path.chmod(0o600)
    except OSError:
        pass


def ensure_config_file() -> None:
    if CONFIG_PATH.exists():
        return
    atomic_json_write(
        CONFIG_PATH,
        {
            "username": "",
            "password": "",
        },
    )


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}


def load_config() -> dict[str, Any]:
    ensure_config_file()
    config = load_json(CONFIG_PATH)
    username = str(config.get("username", "")).strip()
    password = str(config.get("password", ""))
    if not username or not password:
        fail(
            "config_missing",
            "请在 " + str(CONFIG_PATH) + " 中填写滴答清单用户名和密码",
            configured=False,
        )
    return config


def load_session() -> dict[str, Any]:
    return load_json(SESSION_PATH)


def save_session(session: dict[str, Any]) -> None:
    atomic_json_write(SESSION_PATH, session)


def get_device_id(config: dict[str, Any], session: dict[str, Any]) -> str:
    configured = str(config.get("deviceId", "")).strip()
    if configured:
        return configured

    cached = str(session.get("deviceId", "")).strip()
    if cached:
        return cached

    seed = (
        str(config.get("username", ""))
        + "\0"
        + socket.gethostname()
        + "\0quickshell-dida365"
    ).encode("utf-8")
    return hashlib.sha256(seed).hexdigest()[:24]


def make_x_device(config: dict[str, Any], session: dict[str, Any]) -> str:
    return json.dumps(
        {
            "platform": "web",
            "os": "Linux x86_64",
            "device": "Chrome 153.0.0.0",
            "name": "QuickShell",
            "version": 8225,
            "id": get_device_id(config, session),
            "channel": "website",
            "campaign": "",
            "websocket": "",
        },
        separators=(",", ":"),
    )


def request(
    method: str,
    url: str,
    config: dict[str, Any],
    session: dict[str, Any],
    *,
    token: str = "",
    payload: Any = None,
) -> tuple[Any, Any]:
    headers = {
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "zh-CN,zh;q=0.9",
        "Content-Type": "application/json;charset=UTF-8",
        "User-Agent": (
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"
        ),
        "Origin": "https://dida365.com",
        "Referer": "https://dida365.com/",
        "hl": "zh_CN",
        "x-device": make_x_device(config, session),
        "x-tz": "Asia/Shanghai",
    }
    if token:
        headers["Cookie"] = "t=" + token

    body = None
    if payload is not None:
        body = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

    req = Request(url, data=body, headers=headers, method=method)
    try:
        with urlopen(req, timeout=20) as response:
            raw = response.read().decode("utf-8", errors="replace")
            if not raw:
                data: Any = {}
            else:
                try:
                    data = json.loads(raw)
                except json.JSONDecodeError:
                    data = raw
            return data, response.headers
    except HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        raise ApiError(exc.code, raw, exc.headers.get("Retry-After")) from exc
    except URLError as exc:
        raise ApiError(0, str(exc.reason)) from exc


def load_auth_state() -> dict[str, Any]:
    return load_json(AUTH_STATE_PATH)


def save_auth_backoff(seconds: int, reason: str) -> None:
    atomic_json_write(
        AUTH_STATE_PATH,
        {
            "nextAllowed": int(time.time()) + seconds,
            "reason": reason,
        },
    )


def clear_auth_backoff() -> None:
    try:
        AUTH_STATE_PATH.unlink()
    except FileNotFoundError:
        pass


def login(config: dict[str, Any], session: dict[str, Any]) -> str:
    auth_state = load_auth_state()
    next_allowed = int(auth_state.get("nextAllowed", 0) or 0)
    now = int(time.time())
    if next_allowed > now:
        minutes = max(1, (next_allowed - now + 59) // 60)
        fail(
            "login_cooldown",
            "滴答登录暂时处于冷却期，请约 " + str(minutes) + " 分钟后重试",
            details=str(auth_state.get("reason", "")),
        )

    try:
        data, headers = request(
            "POST",
            LOGIN_URL,
            config,
            session,
            payload={
                "username": config["username"],
                "password": config["password"],
            },
        )
    except ApiError as exc:
        if exc.status == 429:
            try:
                seconds = max(3600, int(exc.retry_after or "0"))
            except ValueError:
                seconds = 3600
            save_auth_backoff(seconds, "HTTP 429")
            fail("rate_limited", "滴答登录请求过于频繁，已停止自动重试", details=exc.body)

        if exc.status >= 500 or exc.status == 0:
            save_auth_backoff(300, "HTTP " + str(exc.status))

        fail("login_failed", "滴答清单登录失败", details=exc.body)

    token = ""
    if isinstance(data, dict):
        token = str(data.get("token", "")).strip()

    if not token:
        cookies = SimpleCookie()
        for value in headers.get_all("Set-Cookie", []):
            cookies.load(value)
        if "t" in cookies:
            token = cookies["t"].value

    if not token:
        fail("login_failed", "滴答登录成功响应中没有会话 token", details=str(data))

    new_session = {
        "token": token,
        "deviceId": get_device_id(config, session),
        "savedAt": int(time.time()),
    }
    if isinstance(data, dict) and data.get("userId") is not None:
        new_session["userId"] = data.get("userId")

    save_session(new_session)
    clear_auth_backoff()
    session.clear()
    session.update(new_session)
    return token


def token_for_request(config: dict[str, Any], session: dict[str, Any]) -> str:
    token = str(session.get("token", "")).strip()
    if token:
        return token
    return login(config, session)


def authenticated_request(
    method: str,
    path: str,
    config: dict[str, Any],
    session: dict[str, Any],
    *,
    payload: Any = None,
) -> tuple[Any, Any]:
    token = token_for_request(config, session)

    try:
        return request(method, API_BASE + path, config, session, token=token, payload=payload)
    except ApiError as exc:
        if exc.status != 401:
            raise

        # A real 401 means the cached session is no longer valid.
        # Clear only the token, then perform exactly one fresh sign-on.
        session.pop("token", None)
        save_session(session)
        token = login(config, session)
        return request(method, API_BASE + path, config, session, token=token, payload=payload)


def clean_project(project: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": str(project.get("id", "")),
        "name": str(project.get("name", "") or "未命名清单"),
        "color": project.get("color"),
        "sortOrder": project.get("sortOrder", 0),
    }


def clean_task(task: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": str(task.get("id", "")),
        "projectId": str(task.get("projectId", "")),
        "title": str(task.get("title", "") or "未命名任务"),
        "priority": int(task.get("priority", 0) or 0),
        "sortOrder": task.get("sortOrder", 0),
        "startDate": task.get("startDate"),
        "dueDate": task.get("dueDate"),
        "isAllDay": bool(task.get("isAllDay", False)),
    }


def sync() -> None:
    config = load_config()
    session = load_session()

    try:
        data, _ = authenticated_request("GET", "/batch/check/0", config, session)
    except ApiError as exc:
        if exc.status == 500 and "access_forbidden" in exc.body:
            fail(
                "access_forbidden",
                "滴答拒绝了当前设备标识；可在 dida365.json 中额外配置浏览器的 deviceId",
                details=exc.body,
            )
        fail(
            "sync_failed",
            "同步滴答清单失败",
            details="HTTP " + str(exc.status) + ": " + exc.body,
        )

    if not isinstance(data, dict):
        fail("bad_response", "滴答同步返回了无法识别的数据")

    inbox_id = str(data.get("inboxId", ""))
    profiles = data.get("projectProfiles") or []
    projects: list[dict[str, Any]] = []

    if inbox_id:
        projects.append(
            {
                "id": inbox_id,
                "name": "收集箱",
                "color": None,
                "sortOrder": 2**63 - 1,
            }
        )

    if isinstance(profiles, list):
        for project in profiles:
            if not isinstance(project, dict):
                continue
            if project.get("closed") is True:
                continue
            if str(project.get("kind", "TASK")).upper() == "NOTE":
                continue

            item = clean_project(project)
            if not item["id"] or item["id"] == inbox_id:
                continue
            projects.append(item)

    bean = data.get("syncTaskBean") or {}
    updates = bean.get("update") if isinstance(bean, dict) else []
    tasks: list[dict[str, Any]] = []

    if isinstance(updates, list):
        for task in updates:
            if not isinstance(task, dict):
                continue
            if int(task.get("status", 0) or 0) != 0:
                continue
            if str(task.get("kind", "TEXT")).upper() == "NOTE":
                continue

            item = clean_task(task)
            if item["id"] and item["projectId"]:
                tasks.append(item)

    tasks.sort(key=lambda item: int(item.get("sortOrder", 0) or 0), reverse=True)

    emit(
        {
            "ok": True,
            "configured": True,
            "configPath": str(CONFIG_PATH),
            "inboxId": inbox_id,
            "projects": projects,
            "tasks": tasks,
        }
    )


def complete(task_id: str, project_id: str) -> None:
    config = load_config()
    session = load_session()

    try:
        data, _ = authenticated_request(
            "POST",
            "/batch/task",
            config,
            session,
            payload={
                "update": [
                    {
                        "id": task_id,
                        "projectId": project_id,
                        "status": 2,
                    }
                ]
            },
        )
    except ApiError as exc:
        fail(
            "complete_failed",
            "完成任务失败",
            details="HTTP " + str(exc.status) + ": " + exc.body,
        )

    if isinstance(data, dict):
        errors = data.get("id2error") or {}
        if isinstance(errors, dict) and errors:
            fail(
                "complete_failed",
                "滴答清单没有完成该任务",
                details=json.dumps(errors, ensure_ascii=False),
            )

    emit({"ok": True, "taskId": task_id, "projectId": project_id})


def main() -> None:
    if len(sys.argv) < 2:
        fail("usage", "用法: dida365.py sync | complete <taskId> <projectId>")

    command = sys.argv[1]

    if command == "sync":
        sync()
    elif command == "complete" and len(sys.argv) == 4:
        complete(sys.argv[2], sys.argv[3])
    else:
        fail("usage", "用法: dida365.py sync | complete <taskId> <projectId>")


if __name__ == "__main__":
    main()
