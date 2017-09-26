-- Run this before tests:

DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

CREATE TABLE users(
  id          SERIAL PRIMARY KEY,
  referrer_id INT                     REFERENCES users (id),
  role        INT           NOT NULL  DEFAULT 0,
  name        VARCHAR(100)  NOT NULL,
  created_at  TIMESTAMPTZ   NOT NULL,
  updated_at  TIMESTAMPTZ
);

CREATE TABLE posts(
  id          SERIAL PRIMARY KEY,
  author_id   INT         NOT NULL  REFERENCES users (id),
  editor_id   INT                   REFERENCES users (id),
  content     TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL,
  updated_at  TIMESTAMPTZ
);
