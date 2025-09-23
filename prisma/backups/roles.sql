
\restrict X0MocNxsJREBahqDfY1MUxlF1GI1lNG9ExB9XrX98Eiev48hNLSlbR81X5GGwTc

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

ALTER ROLE "anon" SET "statement_timeout" TO '3s';

ALTER ROLE "authenticated" SET "statement_timeout" TO '8s';

ALTER ROLE "authenticator" SET "statement_timeout" TO '8s';

\unrestrict X0MocNxsJREBahqDfY1MUxlF1GI1lNG9ExB9XrX98Eiev48hNLSlbR81X5GGwTc

RESET ALL;
