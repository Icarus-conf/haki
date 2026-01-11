#!/bin/bash
docker exec chat_db psql -U user -d chat_db -c "TRUNCATE TABLE friend_requests, friendships, messages, users RESTART IDENTITY CASCADE;"
