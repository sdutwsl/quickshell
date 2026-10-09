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
import re
import secrets
import socket
import sys
from datetime import datetime, timezone
from http.cookies import SimpleCookie
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

API_ORIGIN = "https://api.dida365.com"
API_V2 = API_ORIGIN + "/api/v2"
API_V3 = API_ORIGIN + "/api/v3"
LOGIN_URL = API_V2 + "/user/signon?wc=true&remember=true"

CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
CONFIG_DIR = CONFIG_HOME / "quickshell"
CACHE_DIR = CACHE_HOME / "quickshell"
CONFIG_PATH = CONFIG_DIR / "dida365.json"
SESSION_PATH = CACHE_DIR / "dida365-session.json"
SNAPSHOT_PATH = CACHE_DIR / "dida365-snapshot.json"


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


def atomic_json_write(path: Path, data: Any) -> None:
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


def get_websocket_id(session: dict[str, Any]) -> str:
    value = str(session.get("websocket", "")).strip()
    if re.fullmatch(r"[0-9a-fA-F]{24}", value):
        return value.lower()
    return secrets.token_hex(12)


def make_x_device(
    config: dict[str, Any],
    session: dict[str, Any],
    *,
    for_login: bool = False,
) -> str:
    return json.dumps(
        {
            "platform": "web",
            "os": "Linux x86_64",
            "device": "Chrome 153.0.0.0",
            "name": "",
            "version": 8225,
            "id": get_device_id(config, session),
            "channel": "website",
            "campaign": "",
            "websocket": "" if for_login else get_websocket_id(session),
        },
        separators=(",", ":"),
    )


def cookie_values(headers: Any) -> dict[str, str]:
    cookies = SimpleCookie()
    for value in headers.get_all("Set-Cookie", []):
        try:
            cookies.load(value)
        except Exception:
            continue
    return {key: morsel.value for key, morsel in cookies.items()}


def request(
    method: str,
    url: str,
    config: dict[str, Any],
    session: dict[str, Any],
    *,
    authenticated: bool = False,
    payload: Any = None,
    login_request: bool = False,
) -> tuple[Any, Any]:
    headers = {
        "Accept": "*/*" if login_request else "application/json, text/plain, */*",
        "Accept-Language": "zh-CN,zh;q=0.9",
        "Content-Type": "application/json" if login_request else "application/json;charset=UTF-8",
        "User-Agent": (
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"
        ),
        "Origin": "https://dida365.com",
        "Referer": "https://dida365.com/",
        "x-device": make_x_device(config, session, for_login=login_request),
    }

    if login_request:
        headers["X-Requested-With"] = "XMLHttpRequest"
    else:
        headers["hl"] = "zh_CN"
        headers["x-tz"] = "Asia/Shanghai"
        headers["traceid"] = secrets.token_hex(12)

    if authenticated:
        token = str(session.get("token", "")).strip()
        csrf = str(session.get("csrfToken", "")).strip()
        user_id = str(session.get("userId", "")).strip()

        cookie_parts = []
        if token:
            cookie_parts.append("t=" + token)
        if csrf:
            cookie_parts.append("_csrf_token=" + csrf)
            headers["x-csrftoken"] = csrf
        if user_id:
            cookie_parts.append("ap_user_id=" + user_id)
        if cookie_parts:
            headers["Cookie"] = "; ".join(cookie_parts)

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


def login_payload(config: dict[str, Any]) -> dict[str, str]:
    identifier = str(config["username"]).strip()
    payload = {"password": str(config["password"])}

    login_field = str(config.get("loginField", "")).strip().lower()
    if login_field in {"phone", "username"}:
        payload[login_field] = identifier
        return payload

    compact_phone = re.sub(r"[\s()+-]", "", identifier)
    if compact_phone.isdigit():
        payload["phone"] = identifier
    else:
        payload["username"] = identifier
    return payload


def login(config: dict[str, Any], session: dict[str, Any]) -> dict[str, Any]:
    try:
        data, headers = request(
            "POST",
            LOGIN_URL,
            config,
            session,
            payload=login_payload(config),
            login_request=True,
        )
    except ApiError as exc:
        if exc.status == 429:
            suffix = ""
            if exc.retry_after:
                suffix = "，服务端 Retry-After=" + str(exc.retry_after)
            fail(
                "rate_limited",
                "滴答登录请求过于频繁，请稍后再试" + suffix,
                details=exc.body,
            )

        fail(
            "login_failed",
            "滴答清单登录失败",
            details="HTTP " + str(exc.status) + ": " + exc.body,
        )

    if not isinstance(data, dict):
        fail("login_failed", "滴答登录返回了无法识别的数据", details=str(data))

    cookies = cookie_values(headers)
    token = str(data.get("token", "") or cookies.get("t", "")).strip()
    csrf = str(cookies.get("_csrf_token", "")).strip()

    if not token:
        fail("login_failed", "滴答登录成功响应中没有会话 token", details=str(data))
    if not csrf:
        fail("login_failed", "滴答登录响应中没有 _csrf_token", details=str(data))

    new_session = {
        "token": token,
        "csrfToken": csrf,
        "deviceId": get_device_id(config, session),
        "websocket": get_websocket_id(session),
        "savedAt": int(datetime.now(tz=timezone.utc).timestamp()),
    }

    if data.get("userId") is not None:
        new_session["userId"] = str(data.get("userId"))
    if data.get("inboxId") is not None:
        new_session["inboxId"] = str(data.get("inboxId"))

    save_session(new_session)
    session.clear()
    session.update(new_session)
    return session


def ensure_authenticated(config: dict[str, Any], session: dict[str, Any]) -> None:
    token = str(session.get("token", "")).strip()
    csrf = str(session.get("csrfToken", "")).strip()

    # Old versions of this integration cached only t. Re-login once so POSTs
    # mirror the browser flow and carry both t and _csrf_token/x-csrftoken.
    if not token or not csrf:
        login(config, session)


def authenticated_request(
    method: str,
    url: str,
    config: dict[str, Any],
    session: dict[str, Any],
    *,
    payload: Any = None,
) -> tuple[Any, Any]:
    ensure_authenticated(config, session)

    try:
        return request(
            method,
            url,
            config,
            session,
            authenticated=True,
            payload=payload,
        )
    except ApiError as exc:
        if exc.status not in {401, 403}:
            raise

        # A stale session is refreshed once. There is deliberately no local
        # hour-long "cooldown"; any 429 is surfaced exactly as a login error.
        session.pop("token", None)
        session.pop("csrfToken", None)
        save_session(session)
        login(config, session)

        return request(
            method,
            url,
            config,
            session,
            authenticated=True,
            payload=payload,
        )


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


def fetch_snapshot(config: dict[str, Any], session: dict[str, Any]) -> dict[str, Any]:
    try:
        data, _ = authenticated_request(
            "GET",
            API_V3 + "/batch/check/0",
            config,
            session,
        )
    except ApiError as exc:
        fail(
            "sync_failed",
            "同步滴答清单失败",
            details="HTTP " + str(exc.status) + ": " + exc.body,
        )

    if not isinstance(data, dict):
        fail("bad_response", "滴答同步返回了无法识别的数据")

    return data


def snapshot_parts(data: dict[str, Any]) -> tuple[str, list[dict[str, Any]], list[dict[str, Any]], dict[str, dict[str, Any]]]:
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
    raw_tasks: dict[str, dict[str, Any]] = {}

    if isinstance(updates, list):
        for task in updates:
            if not isinstance(task, dict):
                continue
            if int(task.get("status", 0) or 0) != 0:
                continue
            if int(task.get("deleted", 0) or 0) != 0:
                continue
            if str(task.get("kind", "TEXT")).upper() == "NOTE":
                continue

            item = clean_task(task)
            if item["id"] and item["projectId"]:
                tasks.append(item)
                raw_tasks[item["id"]] = task

    tasks.sort(key=lambda item: int(item.get("sortOrder", 0) or 0), reverse=True)
    projects.sort(key=lambda item: int(item.get("sortOrder", 0) or 0), reverse=True)

    return inbox_id, projects, tasks, raw_tasks


def sync() -> None:
    config = load_config()
    session = load_session()
    data = fetch_snapshot(config, session)
    inbox_id, projects, tasks, raw_tasks = snapshot_parts(data)

    atomic_json_write(
        SNAPSHOT_PATH,
        {
            "checkPoint": data.get("checkPoint"),
            "tasks": raw_tasks,
        },
    )

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


def dida_utc_now() -> str:
    # The HAR uses e.g. 2026-10-09T06:06:30.000+0000.
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000+0000")


def find_raw_task(
    task_id: str,
    config: dict[str, Any],
    session: dict[str, Any],
) -> dict[str, Any] | None:
    snapshot = load_json(SNAPSHOT_PATH)
    tasks = snapshot.get("tasks")
    if isinstance(tasks, dict):
        task = tasks.get(task_id)
        if isinstance(task, dict):
            return task

    data = fetch_snapshot(config, session)
    _, _, _, raw_tasks = snapshot_parts(data)
    atomic_json_write(
        SNAPSHOT_PATH,
        {
            "checkPoint": data.get("checkPoint"),
            "tasks": raw_tasks,
        },
    )
    task = raw_tasks.get(task_id)
    return task if isinstance(task, dict) else None


def complete(task_id: str, project_id: str) -> None:
    config = load_config()
    session = load_session()
    ensure_authenticated(config, session)

    raw_task = find_raw_task(task_id, config, session)
    if raw_task is None:
        fail("task_not_found", "没有在当前滴答清单数据中找到这个任务")

    if str(raw_task.get("projectId", "")) != project_id:
        fail("task_changed", "任务所属清单已经变化，请先刷新")

    update_task = dict(raw_task)
    now = dida_utc_now()
    update_task["status"] = 2
    update_task["completedTime"] = now
    update_task["modifiedTime"] = now
    update_task["completedUserId"] = session.get("userId")

    payload = {
        "add": [],
        "update": [update_task],
        "delete": [],
        "addAttachments": [],
        "updateAttachments": [],
        "deleteAttachments": [],
    }

    try:
        data, _ = authenticated_request(
            "POST",
            API_V2 + "/batch/task",
            config,
            session,
            payload=payload,
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

    snapshot = load_json(SNAPSHOT_PATH)
    raw_tasks = snapshot.get("tasks")
    if isinstance(raw_tasks, dict) and task_id in raw_tasks:
        del raw_tasks[task_id]
        atomic_json_write(SNAPSHOT_PATH, snapshot)

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
