FROM python:3.12-slim

LABEL 'author.name' = 'toizy'
LABEL 'author.email'  =  'toizy@toizy.ru'
MAINTAINER 'toizy'

WORKDIR /app

COPY . .

RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 8000

CMD ["python3", "main.py"]