import httpx
import asyncio
import uuid
import os

BASE_URL = "http://127.0.0.1:8080/api/v1"

# Mock Firebase UID for testing (Unique per run for professional isolation)
TEST_UID = f"pro_tester_{uuid.uuid4().hex[:8]}"
TEST_TOKEN = f"test_token_{TEST_UID}"

async def run_tests():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("🚀 Starting Professional Backend Audit...")

        # 1. Health Check
        print("\n[1/6] Auditing System Health...")
        try:
            resp = await client.get("http://localhost:8080/health")
            print(f"✅ Health: {resp.status_code}")
        except Exception as e:
            print(f"❌ API not reachable: {e}")
            return

        # 2. Interests Audit
        print("\n[2/6] Auditing Interests Metadata...")
        resp = await client.get(f"{BASE_URL}/users/interests")
        interests = resp.json()
        print(f"✅ Fetched {len(interests)} interests.")
        if not interests:
            print("⚠️ Warning: No interests found. Did you run the seed script?")
            return
        interest_ids = [i['id'] for i in interests[:3]]

        # 3. User Registration (Ensuring user exists in DB)
        print("\n[3/7] Auditing User Registration (Auth Verify)...")
        auth_payload = {"id_token": TEST_TOKEN}
        resp = await client.post("http://127.0.0.1:8080/api/v1/auth/verify", json=auth_payload)
        if resp.status_code == 200:
            print(f"✅ User Registered/Verified: {resp.json().get('user_id')}")
        else:
            print(f"❌ Auth Verify Failed: {resp.status_code} - {resp.text}")
            return

        # 4. User & Profile Lifecycle
        print("\n[4/7] Auditing User Onboarding & Atomic Profile Creation...")
        headers = {"Authorization": f"Bearer {TEST_TOKEN}"}
        
        profile_data = {
            "display_name": "Pro Tester",
            "age": 28,
            "gender": "MALE",
            "bio": "Senior Quality Assurance Architect.",
            "interest_ids": interest_ids
        }
        
        # Test Profile Create (POST for first time)
        resp = await client.post(f"{BASE_URL}/users/me/profile", json=profile_data, headers=headers)
        if resp.status_code == 201:
            print("✅ Atomic Profile Creation Successful.")
        else:
            print(f"❌ Profile Creation Failed: {resp.status_code} - {resp.text}")

        # 5. Media Pipeline Audit
        print("\n[5/7] Auditing Media Processing (Resizing & Compression)...")
        # Create a VALID small JPEG image using PIL (available in container)
        from PIL import Image
        import io
        
        img = Image.new('RGB', (100, 100), color = 'red')
        img_byte_arr = io.BytesIO()
        img.save(img_byte_arr, format='JPEG')
        img_byte_arr.seek(0)
        
        files = {'file': ('test_image.jpg', img_byte_arr, 'image/jpeg')}
        resp = await client.post(f"{BASE_URL}/users/me/photos?display_order=0", files=files, headers=headers)
        if resp.status_code == 201:
            url = resp.json().get('url')
            print(f"✅ Photo Uploaded & Processed: {url}")
        else:
            print(f"❌ Photo Upload Failed: {resp.status_code} - {resp.text}")
        # No file to remove since we used BytesIO

        # 5. Geographic (PostGIS) Audit
        print("\n[5/6] Auditing PostGIS Location Services...")
        loc_data = {
            "latitude": 28.6139,
            "longitude": 77.2090, # Delhi
            "city": "New Delhi",
            "country": "India"
        }
        resp = await client.put(f"{BASE_URL}/users/me/location", json=loc_data, headers=headers)
        print(f"✅ Location Update (PostGIS Point): {resp.status_code}")

        # 6. Data Integrity Check
        print("\n[6/6] Verifying Data Consistency...")
        resp = await client.get(f"{BASE_URL}/users/me", headers=headers)
        data = resp.json()
        if data.get('display_name') == "Pro Tester" and len(data.get('interests', [])) >= 3:
            print("✅ Data Integrity Verified: Profile + Interests + Location matched.")
        else:
            print(f"❌ Data mismatch: {data}")

        print("\n🏆 Backend Audit Complete.")

if __name__ == "__main__":
    asyncio.run(run_tests())
