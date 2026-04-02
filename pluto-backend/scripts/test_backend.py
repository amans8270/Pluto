"""
Comprehensive Backend Test Script
Tests all API endpoints, photo uploads, and functionality
"""

import asyncio
import uuid
import io
import base64
from pathlib import Path

import httpx


BASE_URL = "http://localhost:8080"
API_V1 = f"{BASE_URL}/api/v1"


def create_test_user_token(user_id: str) -> str:
    return f"test_token_{user_id}"


class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    RESET = "\033[0m"


def print_test(name: str, passed: bool, details: str = ""):
    status = (
        f"{Colors.GREEN}✓ PASS{Colors.RESET}"
        if passed
        else f"{Colors.RED}✗ FAIL{Colors.RESET}"
    )
    print(f"{status} {name}")
    if details:
        print(f"     {details}")


async def test_health():
    print(f"\n{Colors.BLUE}═══ Test 1: Health Check{Colors.RESET}")
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{BASE_URL}/health")
        passed = resp.status_code == 200 and resp.json().get("status") == "ok"
        print_test("Health endpoint", passed, resp.text)
        return passed


async def test_auth_verify():
    print(f"\n{Colors.BLUE}═══ Test 2: Auth Verify{Colors.RESET}")
    async with httpx.AsyncClient() as client:
        test_uid = str(uuid.uuid4())
        token = create_test_user_token(test_uid)

        resp = await client.post(f"{API_V1}/auth/verify", json={"id_token": token})
        passed = resp.status_code == 200
        data = resp.json() if passed else {}
        user_id = data.get("user_id")

        print_test("Auth verify creates new user", passed, f"user_id: {user_id}")

        resp2 = await client.post(
            f"{API_V1}/auth/verify",
            json={"id_token": token, "fcm_token": "test_fcm_token_123"},
        )
        print_test(
            "Auth with FCM token",
            resp2.status_code == 200,
            f"status: {resp2.status_code}",
        )

        return passed, test_uid, user_id


async def test_user_profile(token: str):
    print(f"\n{Colors.BLUE}═══ Test 3: User Profile{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        # Get my profile - may return 404 for new users (no profile yet)
        resp = await client.get(f"{API_V1}/users/me", headers=headers)
        profile_exists = resp.status_code == 200
        print_test(
            "Get my profile (before creating)",
            profile_exists or resp.status_code == 404,
            f"status: {resp.status_code}"
            + (" (new user, expected)" if resp.status_code == 404 else ""),
        )

        # Create profile first if not exists
        if resp.status_code == 404 or resp.status_code == 200:
            profile_data = {
                "display_name": "Test User",
                "bio": "Testing my app!",
                "age": 25,
                "gender": "MALE",
                "occupation": "Tester",
                "education": "Test University",
                "languages": ["English"],
            }
            resp2 = await client.post(
                f"{API_V1}/users/me/profile", json=profile_data, headers=headers
            )
            passed2 = resp2.status_code in [200, 201]
            print_test("Create profile", passed2, f"status: {resp2.status_code}")
            if not passed2:
                print(f"     Error: {resp2.text[:200]}")

            # Update profile
            update_data = {"bio": "Updated bio for testing!"}
            resp3 = await client.put(
                f"{API_V1}/users/me/profile", json=update_data, headers=headers
            )
            passed3 = resp3.status_code == 200
            print_test("Update profile", passed3, f"status: {resp3.status_code}")

        return passed2


async def test_photo_upload(token: str):
    print(f"\n{Colors.BLUE}═══ Test 4: Photo Upload{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}

    # 1x1 red pixel PNG
    fake_image = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
    )

    async with httpx.AsyncClient() as client:
        files = {"file": ("test_photo.png", io.BytesIO(fake_image), "image/png")}

        resp = await client.post(
            f"{API_V1}/users/me/photos", files=files, headers=headers
        )
        passed = resp.status_code in [200, 201]
        data = resp.json() if passed else {}
        print_test(
            "Upload photo",
            passed,
            f"status: {resp.status_code}, url: {data.get('url', 'N/A')}",
        )
        if not passed:
            print(f"     Error: {resp.text[:200]}")

        return passed


async def test_interests(token: str):
    print(f"\n{Colors.BLUE}═══ Test 5: Interests{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        # Get available interests
        resp = await client.get(f"{API_V1}/users/interests")
        passed = resp.status_code == 200
        data = resp.json() if passed else []

        print_test("Get available interests", passed, f"count: {len(data)}")

        # Update user interests (needs at least 3 IDs)
        if passed and len(data) >= 3:
            interest_ids = [data[0]["id"], data[1]["id"], data[2]["id"]]
            resp2 = await client.put(
                f"{API_V1}/users/me/interests",
                json={"interest_ids": interest_ids},
                headers=headers,
            )
            passed2 = resp2.status_code in [200, 204]
            print_test("Update interests", passed2, f"status: {resp2.status_code}")
        else:
            print_test("Update interests", False, "Not enough interests available")

        return passed


async def test_location(token: str):
    print(f"\n{Colors.BLUE}═══ Test 6: Location Update{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        resp = await client.put(
            f"{API_V1}/users/me/location",
            json={"latitude": 28.6139, "longitude": 77.2090, "city": "New Delhi"},
            headers=headers,
        )
        passed = resp.status_code in [200, 204]
        print_test("Update location", passed, f"status: {resp.status_code}")
        if not passed:
            print(f"     Error: {resp.text[:200]}")

        return passed


async def test_discovery(token: str):
    print(f"\n{Colors.BLUE}═══ Test 7: Discovery{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{API_V1}/swipes/discover", headers=headers)
        passed = resp.status_code == 200
        data = resp.json() if passed else {}
        candidates = data.get("candidates", [])

        print_test("Get discover feed", passed, f"candidates: {len(candidates)}")
        if not passed:
            print(f"     Error: {resp.text[:200]}")

        return passed, candidates


async def test_swipe(token: str, candidates: list):
    print(f"\n{Colors.BLUE}═══ Test 8: Swipe Actions{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        if candidates:
            target_id = candidates[0]["id"]

            resp = await client.post(
                f"{API_V1}/swipes/",
                json={"target_user_id": target_id, "mode": "DATE", "action": "LIKE"},
                headers=headers,
            )
            passed = resp.status_code in [200, 201]
            data = resp.json() if passed else {}
            print_test(
                "Swipe LIKE",
                passed,
                f"matched: {data.get('matched', False)}, status: {resp.status_code}",
            )
            if not passed:
                print(f"     Error: {resp.text[:200]}")
        else:
            print_test("Swipe LIKE", False, "No candidates to swipe on")
            passed = False

        return passed


async def test_matches(token: str):
    print(f"\n{Colors.BLUE}═══ Test 9: Matches{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{API_V1}/matches/", headers=headers)
        passed = resp.status_code == 200
        data = resp.json() if passed else {}
        matches = data.get("matches", [])

        print_test("Get matches", passed, f"count: {len(matches)}")
        if not passed:
            print(f"     Error: {resp.text[:200]}")

        # Filter by mode
        for mode in ["DATE", "TRAVELBUDDY", "BFF"]:
            resp = await client.get(f"{API_V1}/matches/?mode={mode}", headers=headers)
            print_test(
                f"Matches ({mode})",
                resp.status_code == 200,
                f"status: {resp.status_code}",
            )

        return passed, matches


async def test_chats(token: str):
    print(f"\n{Colors.BLUE}═══ Test 10: Chats & Messages{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{API_V1}/chats/", headers=headers)
        passed = resp.status_code == 200
        data = resp.json() if passed else {}

        print_test("Get chats", passed, f"count: {len(data.get('chats', []))}")
        if not passed:
            print(f"     Error: {resp.text[:200]}")

        return passed


async def test_trips(token: str):
    print(f"\n{Colors.BLUE}═══ Test 11: Trips{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        # List trips (needs lat/lon)
        resp = await client.get(
            f"{API_V1}/trips/?latitude=28.61&longitude=77.20", headers=headers
        )
        passed = resp.status_code == 200
        data = resp.json() if passed else {}

        print_test("List trips", passed, f"total: {data.get('total', 0)}")
        if not passed:
            print(f"     Error: {resp.text[:200]}")

        # Create a trip
        trip_data = {
            "title": "Test Trip to Goa",
            "description": "Testing the trip feature!",
            "destination": "Goa, India",
            "start_date": "2026-06-01",
            "end_date": "2026-06-07",
            "max_members": 10,
            "category": "BEACH",
            "difficulty": "EASY",
        }
        resp2 = await client.post(f"{API_V1}/trips/", json=trip_data, headers=headers)
        passed2 = resp2.status_code in [200, 201]
        print_test("Create trip", passed2, f"status: {resp2.status_code}")
        if not passed2:
            print(f"     Error: {resp2.text[:200]}")

        if passed2:
            trip = resp2.json()
            trip_id = trip.get("id") or trip.get("trip", {}).get("id")

            if trip_id:
                # Get trip details
                resp3 = await client.get(f"{API_V1}/trips/{trip_id}", headers=headers)
                print_test(
                    "Get trip details",
                    resp3.status_code == 200,
                    f"status: {resp3.status_code}",
                )

                # Join trip - may fail with 400 if already a member (creator auto-joins)
                resp4 = await client.post(
                    f"{API_V1}/trips/{trip_id}/join",
                    json={"payment_ref": None},
                    headers=headers,
                )
                passed4 = resp4.status_code in [200, 400]
                print_test(
                    "Join trip",
                    passed4,
                    f"status: {resp4.status_code}"
                    + (" (already member)" if resp4.status_code == 400 else ""),
                )

                # Get trip members
                resp5 = await client.get(
                    f"{API_V1}/trips/{trip_id}/members", headers=headers
                )
                print_test(
                    "Get trip members",
                    resp5.status_code == 200,
                    f"status: {resp5.status_code}",
                )

                # Delete trip
                resp6 = await client.delete(
                    f"{API_V1}/trips/{trip_id}", headers=headers
                )
                print_test(
                    "Delete trip",
                    resp6.status_code == 204,
                    f"status: {resp6.status_code}",
                )

        # My trips
        resp7 = await client.get(f"{API_V1}/trips/my-trips", headers=headers)
        print_test("My trips", resp7.status_code == 200, f"status: {resp7.status_code}")

        return passed


async def test_notifications(token: str):
    print(f"\n{Colors.BLUE}═══ Test 12: Notifications{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{API_V1}/notifications/", headers=headers)
        passed = resp.status_code == 200
        data = resp.json() if passed else {}

        print_test("Get notifications", passed, f"total: {data.get('total', 0)}")

        # Unread count
        resp2 = await client.get(
            f"{API_V1}/notifications/unread-count", headers=headers
        )
        print_test(
            "Get unread count", resp2.status_code == 200, f"status: {resp2.status_code}"
        )

        # Mark all read
        resp3 = await client.put(f"{API_V1}/notifications/read-all", headers=headers)
        print_test(
            "Mark all read", resp3.status_code == 204, f"status: {resp3.status_code}"
        )

        return passed


async def test_websocket(user_id: str, token: str):
    print(f"\n{Colors.BLUE}═══ Test 13: WebSocket{Colors.RESET}")
    try:
        from websockets import connect

        ws_url = f"ws://localhost:8080/ws/{user_id}?token={token}"
        async with connect(ws_url) as websocket:
            await websocket.send('{"type": "ping"}')
            response = await asyncio.wait_for(websocket.recv(), timeout=5)
            passed = "pong" in response

            print_test("WebSocket ping/pong", passed, response[:100])
            return passed
    except Exception as e:
        print_test("WebSocket connection", False, str(e))
        return False


async def test_rate_limiting():
    print(f"\n{Colors.BLUE}═══ Test 14: Rate Limiting{Colors.RESET}")
    async with httpx.AsyncClient() as client:
        got_429 = False
        for i in range(20):
            resp = await client.post(
                f"{API_V1}/auth/verify", json={"id_token": f"test_token_rate_{i}"}
            )
            if resp.status_code == 429:
                got_429 = True
                break

        print_test("Rate limiting active", got_429, f"Got 429: {got_429}")
        return got_429


async def test_user_public(token: str):
    print(f"\n{Colors.BLUE}═══ Test 15: Public User Profile{Colors.RESET}")
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{API_V1}/users/me", headers=headers)
        if resp.status_code == 200:
            data = resp.json()
            my_user_id = str(data.get("id"))
            if my_user_id:
                resp2 = await client.get(
                    f"{API_V1}/users/{my_user_id}", headers=headers
                )
                passed = resp2.status_code == 200
                print_test("Get public profile", passed, f"status: {resp2.status_code}")
                return passed

        print_test(
            "Get public profile",
            False,
            f"Could not get profile (status: {resp.status_code})",
        )
        return False


async def main():
    print(f"\n{Colors.YELLOW}🚀 Starting Pluto Backend Tests{Colors.RESET}")
    print("=" * 50)

    await test_health()

    auth_result = await test_auth_verify()
    if not auth_result[0]:
        print(f"{Colors.RED}Auth failed, stopping tests{Colors.RESET}")
        return

    test_uid = auth_result[1]
    internal_user_id = auth_result[2]
    token = create_test_user_token(test_uid)

    print(f"\n{Colors.GREEN}Testing with token: {token[:30]}...{Colors.RESET}")

    await test_user_profile(token)
    await test_photo_upload(token)
    await test_interests(token)
    await test_location(token)

    disc_result = await test_discovery(token)
    candidates = disc_result[1] if disc_result[0] else []
    await test_swipe(token, candidates)
    await test_matches(token)
    await test_chats(token)
    await test_trips(token)
    await test_notifications(token)
    await test_websocket(internal_user_id, token)
    await test_rate_limiting()
    await test_user_public(token)

    print(f"\n{Colors.YELLOW}🎉 All Tests Complete!{Colors.RESET}")


if __name__ == "__main__":
    asyncio.run(main())
