FROM node:25.2.0-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install 

COPY . . 

FROM node:25.2.0-alpine

WORKDIR /app

COPY --from=build /app .

EXPOSE 4000

CMD ["node","index.js"]



