
\restrict TT475aQtClZfWmftVRrsP10Mpa24ahvsFIfAYKr99hWvCjdtizqA1C8WXb3QU3b

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

ALTER ROLE "anon" SET "statement_timeout" TO '3s';

ALTER ROLE "authenticated" SET "statement_timeout" TO '8s';

ALTER ROLE "authenticator" SET "statement_timeout" TO '8s';

\unrestrict TT475aQtClZfWmftVRrsP10Mpa24ahvsFIfAYKr99hWvCjdtizqA1C8WXb3QU3b

RESET ALL;
