"""In-memory caching for FastAPI using LRU cache."""
import uuid
from functools import lru_cache
from typing import Any
from datetime import datetime, timedelta
import hashlib
import json


class CacheEntry:
    """Simple cache entry with TTL support."""
    __slots__ = ['value', 'expires_at']
    
    def __init__(self, value: Any, ttl_seconds: int = 300):
        self.value = value
        self.expires_at = datetime.utcnow() + timedelta(seconds=ttl_seconds)
    
    def is_expired(self) -> bool:
        return datetime.utcnow() > self.expires_at


class InMemoryCache:
    """Thread-safe in-memory cache with TTL support."""
    
    def __init__(self, default_ttl: int = 300):
        self._cache: dict[str, CacheEntry] = {}
        self._default_ttl = default_ttl
    
    def _make_key(self, prefix: str, *args) -> str:
        key_parts = [prefix] + [str(arg) for arg in args]
        key_str = ":".join(key_parts)
        return hashlib.md5(key_str.encode()).hexdigest()
    
    def get(self, key: str) -> Any | None:
        entry = self._cache.get(key)
        if entry is None:
            return None
        if entry.is_expired():
            del self._cache[key]
            return None
        return entry.value
    
    def set(self, key: str, value: Any, ttl: int | None = None) -> None:
        ttl = ttl or self._default_ttl
        self._cache[key] = CacheEntry(value, ttl)
    
    def delete(self, key: str) -> bool:
        if key in self._cache:
            del self._cache[key]
            return True
        return False
    
    def clear_prefix(self, prefix: str) -> int:
        keys_to_delete = [k for k in self._cache.keys() if k.startswith(prefix)]
        for key in keys_to_delete:
            del self._cache[key]
        return len(keys_to_delete)
    
    def clear(self) -> None:
        self._cache.clear()
    
    def stats(self) -> dict:
        expired_count = sum(1 for e in self._cache.values() if e.is_expired())
        return {
            "total_entries": len(self._cache),
            "expired_entries": expired_count,
            "active_entries": len(self._cache) - expired_count
        }


_cache = InMemoryCache(default_ttl=300)


def get_cache() -> InMemoryCache:
    return _cache


def cache_profile(user_id: uuid.UUID, profile_data: dict, ttl: int = 300) -> None:
    key = f"profile:{user_id}"
    _cache.set(key, profile_data, ttl)


def get_cached_profile(user_id: uuid.UUID) -> dict | None:
    key = f"profile:{user_id}"
    return _cache.get(key)


def invalidate_profile(user_id: uuid.UUID) -> None:
    key = f"profile:{user_id}"
    _cache.delete(key)


def cache_matches(user_id: uuid.UUID, matches_data: list, ttl: int = 60) -> None:
    key = f"matches:{user_id}"
    _cache.set(key, matches_data, ttl)


def get_cached_matches(user_id: uuid.UUID) -> list | None:
    key = f"matches:{user_id}"
    return _cache.get(key)


def invalidate_matches(user_id: uuid.UUID) -> None:
    key = f"matches:{user_id}"
    _cache.delete(key)


def cache_discover_feed(user_id: uuid.UUID, feed_data: list, ttl: int = 30) -> None:
    key = f"discover:{user_id}"
    _cache.set(key, feed_data, ttl)


def get_cached_discover_feed(user_id: uuid.UUID) -> list | None:
    key = f"discover:{user_id}"
    return _cache.get(key)


def invalidate_discover_feed(user_id: uuid.UUID) -> None:
    _cache.clear_prefix(f"discover:{user_id}")


def invalidate_user_caches(user_id: uuid.UUID) -> None:
    invalidate_profile(user_id)
    invalidate_matches(user_id)
    invalidate_discover_feed(user_id)


async def cache_set(key: str, value: str, ttl: int = 300) -> None:
    _cache.set(key, value, ttl)


async def cache_get(key: str) -> str | None:
    return _cache.get(key)


async def cache_delete(key: str) -> None:
    _cache.delete(key)


async def cache_invalidate_prefix(prefix: str) -> None:
    _cache.clear_prefix(prefix)
