import argparse
import json
import os
from typing import Any, Dict, List, Optional

import httpx


def ensure_trailing_slash(url: str) -> str:
    return url if url.endswith("/") else f"{url}/"


def get_env(name: str, default: Optional[str] = None) -> Optional[str]:
    value = os.getenv(name)
    if value is None or value == "":
        return default
    return value


class GravitateClient:
    def __init__(self, base_url: str, client_id: str, client_secret: str, scope: str = "bbd", timeout: int = 60):
        self.base_url = ensure_trailing_slash(base_url)
        self.client_id = client_id
        self.client_secret = client_secret
        self.scope = scope
        self.timeout = timeout
        self._token: Optional[str] = None

    def get_token(self) -> str:
        if self._token:
            return self._token

        url = f"{self.base_url}token"
        resp = httpx.post(
            url,
            data={
                "client_id": self.client_id,
                "client_secret": self.client_secret,
                "scope": self.scope,
            },
            timeout=self.timeout,
        )
        resp.raise_for_status()
        token = resp.json().get("access_token")
        if not token:
            raise RuntimeError("Token endpoint did not return access_token")
        self._token = token
        return token

    def post(self, endpoint: str, payload: Optional[Dict[str, Any]] = None) -> httpx.Response:
        endpoint = endpoint.lstrip("/")
        token = self.get_token()
        return httpx.post(
            f"{self.base_url}{endpoint}",
            headers={"Authorization": f"Bearer {token}"},
            json=payload or {},
            timeout=self.timeout,
        )


DEFAULT_ENDPOINTS: List[str] = [
    "v1/location/all",
    "v1/counterparty/all",
    "v1/trailer/all",
    "v2/order/freight",
    "v1/order/bol_and_drop",
    "v1/price/update_many",
]


def main() -> int:
    parser = argparse.ArgumentParser(description="Gravitate API auth + endpoint explorer")
    parser.add_argument("--base-url", default=get_env("GRAV_BASE_URL", "https://coleman.bb.gravitate.energy/api/"), help="e.g. https://coleman.bb.gravitate.energy/api/")
    parser.add_argument("--client-id", default=get_env("GRAV_CLIENT_ID"))
    parser.add_argument("--client-secret", default=get_env("GRAV_CLIENT_SECRET"))
    parser.add_argument("--scope", default=get_env("GRAV_SCOPE", "bbd"))
    parser.add_argument("--timeout", type=int, default=int(get_env("GRAV_TIMEOUT_SECONDS", "60")))

    parser.add_argument("--endpoint", help="Endpoint path to call, e.g. v1/location/all")
    parser.add_argument("--json", dest="json_payload", help="JSON payload string")
    parser.add_argument("--list-default-endpoints", action="store_true")
    args = parser.parse_args()

    if args.list_default_endpoints:
        print(json.dumps(DEFAULT_ENDPOINTS, indent=2))
        return 0

    missing = [
        name
        for name, value in [
            ("base_url", args.base_url),
            ("client_id", args.client_id),
            ("client_secret", args.client_secret),
        ]
        if not value
    ]
    if missing:
        raise SystemExit(f"Missing required values: {', '.join(missing)}")

    client = GravitateClient(
        base_url=args.base_url,
        client_id=args.client_id,
        client_secret=args.client_secret,
        scope=args.scope,
        timeout=args.timeout,
    )

    endpoint = args.endpoint or "v1/location/all"
    payload: Dict[str, Any] = {}
    if args.json_payload:
        payload = json.loads(args.json_payload)

    response = client.post(endpoint, payload)

    print(f"endpoint={endpoint}")
    print(f"status={response.status_code}")
    print("body=")
    try:
        print(json.dumps(response.json(), indent=2)[:20000])
    except Exception:
        print(response.text[:20000])

    return 0 if response.is_success else 1


if __name__ == "__main__":
    raise SystemExit(main())
