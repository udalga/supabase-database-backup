
\restrict WtuNOb0UcwnYJUw3Xs50bQnPSKcbWNfYBQH8FglTN4eXbC72YC3L9AwUhzgnyUg

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

ALTER ROLE "anon" SET "statement_timeout" TO '3s';

ALTER ROLE "authenticated" SET "statement_timeout" TO '8s';

ALTER ROLE "authenticator" SET "statement_timeout" TO '8s';

\unrestrict WtuNOb0UcwnYJUw3Xs50bQnPSKcbWNfYBQH8FglTN4eXbC72YC3L9AwUhzgnyUg

RESET ALL;
