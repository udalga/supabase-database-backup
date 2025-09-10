
\restrict 4njgJ56C5x4NYuGZxO9CGwgulFiQoGIj9UK5ikGLGbi5Ik3V5Ng5ecICFPCh9GJ

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

ALTER ROLE "anon" SET "statement_timeout" TO '3s';

ALTER ROLE "authenticated" SET "statement_timeout" TO '8s';

ALTER ROLE "authenticator" SET "statement_timeout" TO '8s';

\unrestrict 4njgJ56C5x4NYuGZxO9CGwgulFiQoGIj9UK5ikGLGbi5Ik3V5Ng5ecICFPCh9GJ

RESET ALL;
