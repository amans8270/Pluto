import asyncio
import random
import uuid
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, delete
from geoalchemy2.functions import ST_GeogFromText

from app.core.config import settings
from app.models.user import User
from app.models.profile import Profile
from app.models.photo import Photo
from app.models.location import Location
from app.models.interest import Interest, UserInterest
from app.core.database import Base

# Center of Delhi/NCR for seeding nearby users
LAT_CENTER = 28.6139
LON_CENTER = 77.2090

NAMES = [
    "Aarav Sharma",
    "Ananya Iyer",
    "Ishaan Malhotra",
    "Sanya Gupta",
    "Rohan Verma",
    "Kavya Reddy",
    "Arjun Singh",
    "Mira Kapoor",
    "Vikram Joshi",
    "Priya Nair",
    "Kabir Mehra",
    "Aditi Rao",
    "Sahil Khan",
    "Zoya Hussain",
    "Rahul Bose",
    "Sia Saxena",
    "Neil Fernandez",
    "Alisha Das",
    "Varun Mehta",
    "Tara Pillai",
]

BIOS = [
    "Exploring the hidden gems of the city 🏙️",
    "Coffee enthusiast and bookworm ☕📚",
    "Travel is the only thing you buy that makes you richer ✈️",
    "Fitness junkie 🏋️‍♂️ Always up for a trek!",
    "Foodie at heart 🍝 Let's find the best butter chicken.",
    "Data scientist by day, musician by night 🎸",
    "Art lover and occasional painter 🎨",
    "Looking for a travel buddy for my next trip to Spiti 🏔️",
    "Yoga and mindfulness 🧘‍♀️",
    "Tech enthusiast 💻 Love discussing AI and startups.",
    "Cinema buff 🎬 Tell me your favorite movie!",
    "Always carry a camera 📸 Catching moments.",
    "Sunsets and deep conversations ✨",
    "Dancing through life 💃",
    "Stargazing and space nerd 🌌",
    "Minimalist and sustainability advocate 🌱",
    "Love animals more than humans 🐕",
    "Wanderlust and poetry 🎒✍️",
    "Home chef experimenting with spices 🌶️",
    "Curious soul, always learning 🧠",
]

OCCUPATIONS = [
    "Software Engineer",
    "Architect",
    "Graphic Designer",
    "Doctor",
    "Marketing Manager",
    "Journalist",
    "Chef",
    "Entrepreneur",
    "Flight Attendant",
    "Photographer",
    "Student",
    "Lawyer",
    "Fitness Trainer",
    "HR Professional",
    "Product Manager",
]


async def seed_data():
    engine = create_async_engine(settings.DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # 1. Seed Interests first
        interests_data = [
            {"name": "Hiking", "category": "Outdoors", "icon": "⛰️"},
            {"name": "Photography", "category": "Creative", "icon": "📸"},
            {"name": "Cooking", "category": "Lifestyle", "icon": "🍳"},
            {"name": "Gaming", "category": "Tech", "icon": "🎮"},
            {"name": "Travel", "category": "Adventure", "icon": "✈️"},
            {"name": "Yoga", "category": "Wellness", "icon": "🧘"},
            {"name": "Music", "category": "Entertainment", "icon": "🎵"},
            {"name": "Art", "category": "Creative", "icon": "🎨"},
            {"name": "Reading", "category": "Lifestyle", "icon": "📚"},
            {"name": "Movies", "category": "Entertainment", "icon": "🎬"},
            {"name": "Coffee", "category": "Lifestyle", "icon": "☕"},
            {"name": "Fitness", "category": "Wellness", "icon": "💪"},
            {"name": "Dancing", "category": "Social", "icon": "💃"},
            {"name": "Stargazing", "category": "Outdoors", "icon": "✨"},
            {"name": "Solo Travel", "category": "Travel", "icon": "🎒"},
        ]

        db_interests = []
        for data in interests_data:
            stmt = select(Interest).where(Interest.name == data["name"])
            existing = (await session.execute(stmt)).scalar_one_or_none()
            if not existing:
                interest = Interest(**data)
                session.add(interest)
                db_interests.append(interest)
            else:
                db_interests.append(existing)

        await session.flush()

        # 2. Seed Users
        print(f"Seeding {len(NAMES)} users...")
        for i, name in enumerate(NAMES):
            supabase_uid = f"dummy_user_{i}_{uuid.uuid4().hex[:8]}"

            # Check if exists
            stmt = select(User).where(User.supabase_uid == supabase_uid)
            existing_user = (await session.execute(stmt)).scalar_one_or_none()
            if existing_user:
                continue

            user = User(
                supabase_uid=supabase_uid,
                email=f"user{i}@example.com",
                is_verified=True,
                is_active=True,
            )
            session.add(user)
            await session.flush()

            # Create Profile
            is_male = i % 2 == 0
            profile = Profile(
                user_id=user.id,
                display_name=name,
                bio=BIOS[i % len(BIOS)],
                age=random.randint(20, 35),
                gender="MALE" if is_male else "FEMALE",
                occupation=random.choice(OCCUPATIONS),
                education="University of Delhi",
                is_profile_complete=True,
                active_mode="DATE",
            )
            session.add(profile)

            # Create Location (randomized within ~10km of center)
            lat = LAT_CENTER + random.uniform(-0.1, 0.1)
            lon = LON_CENTER + random.uniform(-0.1, 0.1)
            location = Location(
                user_id=user.id,
                geom=ST_GeogFromText(f"POINT({lon} {lat})"),
                city="New Delhi",
                state="Delhi",
                country="India",
            )
            session.add(location)

            # Add Photos (i.pravatar.cc)
            avatar_id = random.randint(1, 70)
            photo = Photo(
                user_id=user.id,
                gcs_url=f"https://i.pravatar.cc/600?img={avatar_id}",
                display_order=0,
                is_verified=True,
            )
            session.add(photo)

            # Link some interests
            selected_interests = random.sample(db_interests, k=random.randint(3, 5))
            for interest in selected_interests:
                ui = UserInterest(user_id=user.id, interest_id=interest.id)
                session.add(ui)

        try:
            await session.commit()
            print("Successfully seeded database with dummy users and interests! 🚀")
        except Exception as e:
            print(f"Error during seeding: {e}")
            await session.rollback()


if __name__ == "__main__":
    asyncio.run(seed_data())
