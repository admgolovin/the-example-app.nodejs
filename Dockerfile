FROM node

WORKDIR /app

RUN npm cache verify
RUN npm rebuild
RUN npm install -g contentful-cli

COPY package.json .
RUN npm install -g nodemon

COPY . .

EXPOSE 3000
