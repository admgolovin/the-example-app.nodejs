FROM node

WORKDIR /app

RUN npm cache verify
RUN npm rebuild
RUN npm install -g contentful-cli

COPY package.json .
RUN npm install -g nodemon

COPY . .

USER node
EXPOSE 3000

CMD ["npm", "run", "start:dev"]
