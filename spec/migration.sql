-- Run this before tests:

DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS pg_numeric;
DROP TABLE IF EXISTS enums;
DROP TABLE IF EXISTS enum_arrays;

CREATE TABLE users(
  id          SERIAL PRIMARY KEY,
  referrer_id INT                     REFERENCES users (id),
  active      BOOL          NOT NULL  DEFAULT true,
  role        INT           NOT NULL  DEFAULT 0,
  name        VARCHAR(100)  NOT NULL,
  permissions SMALLINT[]    NOT NULL  DEFAULT '{0}',
  created_at  TIMESTAMPTZ   NOT NULL  DEFAULT NOW(),
  updated_at  TIMESTAMPTZ
);

CREATE TABLE posts(
  id          SERIAL PRIMARY KEY,
  author_id   INT         NOT NULL  REFERENCES users (id),
  editor_id   INT                   REFERENCES users (id),
  content     TEXT        NOT NULL,
  tags        TEXT[],
  created_at  TIMESTAMPTZ NOT NULL  DEFAULT NOW(),
  updated_at  TIMESTAMPTZ
);

CREATE TABLE pg_numeric(
  foo  NUMERIC(16, 8) NOT NULL,
  bar  NUMERIC(16, 8)
);

INSERT INTO pg_numeric (foo, bar) VALUES (12345678.00000001, NULL);

CREATE TABLE enums(
  foo SMALLINT  NOT NULL,
  bar SMALLINT
);

INSERT INTO enums (foo, bar) VALUES (1, NULL);

CREATE TABLE enum_arrays(
  foo SMALLINT[] NOT NULL,
  bar INT[]
);

INSERT INTO enum_arrays (foo, bar) VALUES ('{1,2}', NULL);
