from typing import Optional

import pymongo
from pymongo.errors import PyMongoError
import requests
import uvicorn
from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel


# Подключение к  mongodb
mongo_client = pymongo.MongoClient(f"mongodb://localhost:27017/")
db = mongo_client["bot_tokens"]
collection = db["ip_token_pairs"]
# Создаем TTL индекс
collection.create_index(
    "created_at", expireAfterSeconds=3600
)  # Время жизни индекса в секундах

app = FastAPI()


# Модель данных для хранения IP и токена
class IpTokenPair(BaseModel):
    ip: Optional[str] = None
    token: str


class TelegramMessage(BaseModel):
    token: Optional[str] = None
    chat: int
    thread: Optional[int] = None
    message: str
    parse_mode: Optional[str] = "MarkdownV2"


# Роут для сохранения IP и токена
@app.post("/v1/telegram/set-token")
async def save_token(ip_token: IpTokenPair, request: Request):
    client_ip = ip_token.ip or request.client.host

    # Проверяем, существует ли уже такая пара IP и токена
    existing_entry = collection.find_one({"ip": client_ip, "token": ip_token.token})
    if existing_entry:
        return {"status": "success", "response": "Pair already exists"}

    try:
        # Вставляем новую запись в базу данных
        collection.insert_one({"ip": client_ip, "token": ip_token.token})
        return {"status": "success", "response": "Token saved successfully"}
    except PyMongoError as e:
        return {"status": "failure", "response": f"Failed to insert document: {e}"}


# Роут для получения токена по IP
@app.get("/v1/telegram/get-token/")
async def get_token(ip: str, request: Request):
    client_ip = ip or request.client.host

    # Ищем запись с заданным IP в базе данных
    entry = collection.find_one({"ip": client_ip})
    if entry:
        return {"token": entry["token"]}
    else:
        raise HTTPException(status_code=404, detail="Token not found")


@app.post("/v1/telegram/send/")
async def send_telegram_message(data: TelegramMessage, request: Request):
    client_ip = request.client.host

    # Если токен не передан
    if data.token is None:
        # Ищем запись с заданным IP в базе данных
        entry = collection.find_one({"ip": client_ip})
        # Нашли
        if entry is not None:
            data.token = entry["token"]
        else:
            return {"status": "failure", "response": "No token found in data"}
    else:
        await save_token(IpTokenPair(ip=client_ip, token=data.token), request)

    url = f"https://api.telegram.org/bot{data.token}/sendMessage"
    payload = {
        "chat_id": data.chat,
        "message_thread_id": data.thread,
        "text": data.message,
        "parse_mode": data.parse_mode,
    }

    response = requests.post(url, json=payload)

    if response.status_code != 200:
        return {
            "status": "failure",
            "code": response.status_code,
            "response": response.json(),
        }

    return {"status": "success"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
